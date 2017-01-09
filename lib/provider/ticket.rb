module TaskMapper::Provider
  module Jira
    # Ticket class for taskmapper-jira
    #

    class Ticket < TaskMapper::Provider::Base::Ticket
      extend TaskMapper::Provider::JiraAccessor
      
      attr_accessor :project
      
      module ErrorMessages
        STORY_POINTS_NOT_ENABLED = "Story points are not enabled for Stories in JIRA. Cardboard requires having them enabled."
        STORY_POINTS_VALIDATION  = "We need Story Sizes to be enabled in JIRA to process these requests."
        DEFAULT = "Internal error while communicating to JIRA"
        module API
          CANNOT_SET_STORY_POINTS = "'customfield_10004' cannot be set"
        end
        
      end

      #API = Jira::Ticket # The class to access the api's tickets
      # declare needed overloaded methods here
      def initialize(*args)
        return unless args.present?
        attributes = args.first
        @project   = args[1]
        initializer_object = attributes.is_a?(Hash) ? attributes : build_initializer_object(attributes)
        super(initializer_object)
      end

      def get_meta (project)
        if self.class.jira_project_metadata(project).nil?
          meta = project.metadata
          self.class.jira_project_metadata = meta
        else
          self.class.jira_project_metadata(project)
        end
      end

      def updated_at
        self[:updated_at]
      end

      def created_at
        self[:created_at]
      end

      def status
        self[:status].name.try {|name| name.parameterize.underscore.to_sym} unless self[:status].nil?
      end

      def status=(new_status)
        self[:transition] = new_status
      end

      def href
        options = client_issue.client.options
        "#{options[:site]}#{options[:context_path]}/browse/#{id}"
      end

      def url
        href
      end

      def project
        project_id = system_data[:client].try(:project).try(:id)
        @project ||= jira_client.Project.find(project_id)
      end

      def save
        fields = {}
        transitions = {}
        meta = get_meta(client_issue.project)

        story_points_field = meta['story-story-points'].try(:to_sym)
        epic_link_field    = meta['epic-epic-link'].try(:to_sym)
        epic_name_field    = meta['epic-epic-name'].try(:to_sym)

        fields[:description]       = description if client_field_changed?(:description)
        fields[:summary]           = title.strip if client_field_changed?(:title, :summary)
        fields[epic_name_field]    = title.strip if epic_name_field.present? && is_epic?(self.issuetype) && client_field_changed?(:title, epic_name_field)
        fields[epic_link_field]    = parent      if epic_link_field.present? && client_field_changed?(:parent, epic_link_field)
        fields[story_points_field] = story_size.to_f.prettify if story_points_field.present? && story_points_enabled? && client_field_changed?(:story_size, story_points_field)

        update_status = client_status = nil
        if self.key? :transition
            if self[:transition].is_a? String
              update_status = self[:transition].parameterize.underscore.to_sym
            else
              if self[:transition].key? :name
                update_status = self[:transition].name.parameterize.underscore.to_sym
              end
            end

            if client_issue.send(:status).is_a? String
              client_status = client_issue.send(:status).parameterize.underscore.to_sym
            else
              client_status = client_issue.send(:status).name.parameterize.underscore.to_sym
            end


            if client_status != update_status
              available_transitions = self.class.jira_client.Transition.all(:issue => client_issue)
              available_transitions.each do |transition|
              transition_name = transition.name.try {|name| name.parameterize.underscore.to_sym}
              if transition_name == update_status
                transitions[:id] = transition.id
              end
            end
            end
        end


        client_issue.save({:fields => fields})
        client_issue.fetch

        if transitions.any?
          transition = client_issue.transitions.build
          transition.save!("transition" => transitions)

          status_string = ""
          case self[:transition]
            when 'to_do'
              status_string = "To Do"
            when 'in_progress'
              status_string = "In Progress"
            when 'done'
              status_string = "Done"
            else
              status_string = "To Do"
          end

        end


        self[:updated_at] = client_issue.updated

      end

      def comment(*options)
        nil
      end

      def destroy
        client_issue.delete
      end

      def story_points_enabled?(type = nil, ticket_project = nil)
        self.class.story_points_enabled?(type || self.issuetype, ticket_project || project)
      end

      def is_epic?(type)
        self.class.is_epic?(type)
      end

      #POST /rest/api/2/issue/bulk
      def self.bulk_create(attributes)
        response   = jira_client.post("/rest/api/2/issue/bulk", { issueUpdates: attributes.map{ |attribute| attribute[:data] } }.to_json)
        issue_keys = JSON.parse(response.body)["issues"].map{ |issue| issue["key"] }
        
        issue_data = JSON.parse(response.body)["issues"].each_with_index.inject({}) do |hash, (issue, index)|
          key = issue["key"]
          hash[key] = { card_id: attributes[index].try(:[], :card).try(:id), status:  attributes[index].try(:[], :status) }
          hash 
        end

        json_created_issues = JSON.parse( jira_client.get("/rest/api/2/search?maxResults=1000&jql=" + CGI.escape("issue IN (#{issue_keys.join(',')})") ).body )
        issues = json_created_issues["issues"].map{|json| jira_client.Issue.build(json) }
        issues.each { |issue| create_transition_for_issue(issue, issue_data[issue.key][:status]) }

        {
          issue_data: issue_data.with_indifferent_access,
          tickets: issues.map{ |issue| Ticket.new(issue) }
        }
      rescue JIRA::HTTPError => jira_error
        parsed_response = JSON.parse(jira_error.response.body) if jira_error.response.content_type.include?('application/json')
        msg = parsed_response['errors'].map{ |element| element.values.join('/n') }.join(" ")
        raise TaskMapper::Exception.new(msg)
      end

      def self.create_transition_for_issue(issue, status)
        return unless status.to_s != "to_do" 
        transition_options = { id: transition_number_for_status(status.to_s) }
        transition = issue.transitions.build
        transition.save!(transition: transition_options)
      end

      def self.build_ticket_attributes_for_project(project, options)
        issuetypes         = project.issuetypes
        meta               = project.metadata
        story_points_field = meta['story-story-points']
        epic_link_field    = meta['epic-epic-link']
        epic_name_field    = meta['epic-epic-name'].try(:to_sym)

        if options.key?(:issuetype)
          type = issuetypes.find {|t| t.name.downcase == options[:issuetype] }
        else
          type = issuetypes.find {|t| t.name == 'Story' or t.name == 'New Feature'}
        end

        type = issuetypes.first unless type

        fields = { project: { key: project.key.presence || options[:project_id] } }

        fields[:issuetype] = { id: type.id } if type

        title = options[:title].to_s.strip
        fields[:description]    = options[:description].to_s if options.key?(:description)
        fields[:summary]        = title if options.key?(:title)
        fields[epic_name_field] = title if epic_name_field.present? && is_epic?(type.name)
        fields[epic_link_field.to_sym]     = options[:parent] if epic_link_field.present? && options.key?(:parent)
        fields[story_points_field.to_sym]  = options[:story_size].to_f.prettify if story_points_enabled?(type.name, project) && story_points_field.present? && options.key?(:story_size)
        fields
      end

      def self.transition_number_for_status(status)
        return 21 if status == "in_progress"
        return 31 if status == "done"
        return 11
      end

      def self.create(*options)
        options   = options.first if options.is_a? Array
        project   = jira_client.Project.find(options[:project_id])
        new_issue = jira_client.Issue.build

        begin
          new_issue.save!( { fields: build_ticket_attributes_for_project(project, options) } )
        rescue JIRA::HTTPError => jira_error
          parsed_response = JSON.parse(jira_error.response.body) if jira_error.response.content_type.include?('application/json')
          raise TaskMapper::Exception.new(jira_error_message(parsed_response))
        end

        if options[:status] !=  "to_do"
          transition_options = { id: transition_number_for_status(options[:status]) }
          transition = new_issue.transitions.build
          transition.save!(transition: transition_options)          
        end
        
        new_issue.fetch
        Ticket.new new_issue
      end

      def self.find_by_attributes(project_id, attributes = {})
        search_by_attribute(self.find_all(project_id), attributes)
      end

      def self.find_by_id(project_id, id)
        self.find_all(project_id).find { |ticket| ticket.id == id }
      end

      def self.find_all(project_id)
        jql_query_string = "project = #{project_id} AND issuetype in (Epic, Story)"
        project = jira_client.Project.find(project_id)
        issues = jira_client.Issue.jql(jql_query_string, :max_results => 1000)
        issues.map do |ticket|
          self.new ticket, project
        end
      end

      def self.createmeta(options)
        options = options.with_indifferent_access
        project = options[:project].presence || jira_client.Project.find(options[:project_id])
        project.metadata
      end

      def self.is_epic?(string)
        string.downcase == "epic"
      end

      def self.story_points_enabled?(issuetype, project)
        key = is_epic?(issuetype) ? 'epic-story-points' : 'story-story-points'
        project.metadata[key].present?
      end

      private
        def client_field_changed?(public_field, client_field = nil)
          client_field = public_field if client_field.nil?
          client_issue.send(client_field) != send(public_field)
        end


        def client_issue
          @system_data[:client]
        end

        def jira_error_message(error_response)
          error_message = (parsed_response.presence || [])['errors'].try(:values).try(:join, '/n').presence || ErrorMessages::DEFAULT
          if error_message.include?(ErrorMessages::API::CANNOT_SET_STORY_POINTS)
            ErrorMessages::STORY_POINTS_VALIDATION
          else
            error_message
          end        
        end

        def build_initializer_object(object)
          @system_data = { client: object }
          meta = get_meta(object.project)
          story_points_field = meta['story-story-points'].to_s
          epic_link_field    = meta['epic-epic-link'].to_s

          fields = object.attrs.fetch('fields')

          epic_link = fields.fetch(epic_link_field) if epic_link_field.present? && fields.key?(epic_link_field)

          @description = object.description.to_s

          if is_epic?(object.issuetype.name)
            @title = fields.fetch(meta['epic-epic-name'].to_s)
          else
            @title = object.summary
          end
          
          issuetype = object.issuetype.name.downcase
          story_points = fields.fetch(story_points_field) if fields.key?(story_points_field)
          story_size = story_points.prettify.to_s if story_points.present? && story_points_enabled?(issuetype, object.project)

          { 
            id:  object.key,
            status:  object.status,
            priority:  object.priority,
            issuetype:  issuetype,
            parent:  epic_link,
            title:  @title,
            resolution:  object.resolution,
            created_at:  object.created,
            updated_at:  object.updated,
            description:  @description.to_s,
            assignee:  object.assignee,
            estimate:  object.timeestimate,
            story_size:  story_size,
            requestor:  object.reporter 
          }
        end
    end
  end
end

class Float
  def prettify
    to_i == self ? to_i : self
  end
end
