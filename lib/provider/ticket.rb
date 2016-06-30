module TaskMapper::Provider
  module Jira
    # Ticket class for taskmapper-jira
    #

    class Ticket < TaskMapper::Provider::Base::Ticket
      extend TaskMapper::Provider::JiraAccessor

      #API = Jira::Ticket # The class to access the api's tickets
      # declare needed overloaded methods here
      def initialize(*object)
        if object.first
          object = object.first
          unless object.is_a? Hash
            @system_data = {:client => object}
            meta = get_meta(object.project.key)
            story_points_field = meta['story-story-points']
            epic_link_field = meta['epic-epic-link']
            epic_name_field = meta['epic-epic-name']

            fields = object.attrs.fetch('fields')

            story_points = fields.fetch story_points_field.to_s if fields.key? story_points_field.to_s
            epic_link = nil
            epic_link = fields.fetch epic_link_field.to_s if fields.key? epic_link_field.to_s

            if object.issuetype.name.downcase == 'epic'
              epic_name = fields.fetch epic_name_field.to_s

              @description = object.description.to_s
              @title = epic_name
            else
              @title = object.summary
              @description = object.description.to_s
            end

            story_size = story_points.prettify.to_s unless story_points.nil?

            hash = {:id => object.key,
              :status => object.status,
              :priority => object.priority,
              :issuetype => object.issuetype.name.downcase,
              :parent => epic_link,
              :title => @title,
              :resolution => object.resolution,
              :created_at => object.created,
              :updated_at => object.updated,
              :description => @description.to_s,
              :assignee => object.assignee,
              :estimate => object.timeestimate,
              :story_size => story_size,
              :requestor => object.reporter}

          else
            hash = object
          end
          super(hash)
        end
      end

      def validate_fields_available (meta)
        epic_story_points_missing = meta['epic-story-points'].nil?
        story_story_points_missing = meta['story-story-points'].nil?

        if epic_story_points_missing
          msg = "Story points are not enabled for Epics in JIRA. Cardboard requires having them enabled."
          raise TaskMapper::Exception.new(msg)
        end

        if story_story_points_missing
          msg = "Story points are not enabled for Stories in JIRA. Cardboard requires having them enabled."
          raise TaskMapper::Exception.new(msg)
        end

      end

      def get_meta (project_key)
        if self.class.jira_project_metadata(project_key).nil?
          meta = self.class.createmeta(project_key)
          meta.project_id = project_key
          validate_fields_available(meta)
          self.class.jira_project_metadata = meta
        else
          meta = self.class.jira_project_metadata(project_key)
        end

        meta
      end

      def updated_at
        self[:updated_at]
      end

      def created_at
        self[:created_at]
      end

      def status
        unless self[:status].nil?
          self[:status].name.try {|name| name.parameterize.underscore.to_sym}
        end
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


      def self.create(*options)

        options = options.first if options.is_a? Array

        issuetypes = jira_client.Project.find(options[:project_id]).issuetypes

        if jira_project_metadata(options[:project_id]).nil?
          meta = createmeta(options[:project_id])
          meta.project_id = options[:project_id]
        else
          meta = jira_project_metadata(options[:project_id])
        end

        story_points_field = meta['story-story-points']
        epic_link_field = meta['epic-epic-link']
        epic_name_field = meta['epic-epic-name']

        if options.key? :issuetype
          type = issuetypes.find {|t| t.name.downcase == options[:issuetype] }
        else
          type = issuetypes.find {|t| t.name == 'Story' or t.name == 'New Feature'}
        end

        type = issuetypes.first unless type

        new_issue = jira_client.Issue.build

        fields = {:project => {:key => options[:project_id]}}

        fields[:issuetype] = {:id => type.id} if type

        epic_name_field = epic_name_field.to_sym unless epic_name_field.nil?

        if type.name.downcase == 'epic'
          title = options[:title].strip

          fields[epic_name_field]  = title #if options.key? :title
          fields[:summary] = title
          if options.key? :description
            fields[:description] = options[:description].to_s
          end

        else
          title = options[:title].strip
          fields[:summary] = title if options.key? :title
          fields[:description] = options[:description].to_s if options.key? :description
        end

        epic_link_field = epic_link_field.to_sym unless epic_link_field.nil?
        fields[epic_link_field]  = options[:parent] if options.key? :parent
        story_points_field = story_points_field.to_sym unless story_points_field.nil?
        fields[story_points_field]  = options[:story_size].to_f.prettify if options.key? :story_size

        begin
          new_issue.save!({:fields => fields})
          new_issue.fetch
        rescue JIRA::HTTPError => jira_error
          parsed_response = JSON.parse(jira_error.response.body) if jira_error.response.content_type.include?('application/json')
          the_errors = parsed_response['errors']
          msg = the_errors.values.join('/n')

          if msg.include? "'customfield_10004' cannot be set"
            msg = "We need Story Sizes to be enabled in JIRA to process these requests."
          end

          raise TaskMapper::Exception.new(msg)
        end

        transitions = {}

        update_status = options[:status] !=  "to_do"


        if update_status

          update_status = options[:status]
          transition_id = nil

          case update_status
            when "in_progress"
              transition_id = 21
            when "done"
              transition_id = 31
            else
              transition_id = 11
          end
          transitions[:id] = transition_id

        end

        if transitions.any?
          transition = new_issue.transitions.build
          transition.save!("transition" => transitions)
          new_issue.fetch
        end


        Ticket.new new_issue
      end

      def save
        fields = {}
        transitions = {}

        meta = get_meta(client_issue.project.key)

        story_points_field = meta['story-story-points']
        epic_link_field = meta['epic-epic-link']
        epic_name_field = meta['epic-epic-name']

        epic_name_field = epic_name_field.to_sym
        epic_link_field = epic_link_field.to_sym
        story_points_field = story_points_field.to_sym

        epic_story_points_missing = meta['epic-story-points'].nil?
        story_story_points_missing = meta['story-story-points'].nil?

        if epic_story_points_missing
          msg = "Story points are not enabled for Epics in JIRA."
          raise TaskMapper::Exception.new(msg)
        end

        if story_story_points_missing
          msg = "Story points are not enabled for Stories in JIRA. Cardboard requires having them enabled."
          raise TaskMapper::Exception.new(msg)
        end

        if self.issuetype == "epic"
          fields[epic_name_field] = title.strip if client_field_changed?(:title, epic_name_field)
          fields[:description] =  description if client_field_changed?(:description)
        else
          fields[:summary] = title.strip if client_field_changed?(:title, :summary)
          fields[:description] =  description if client_field_changed?(:description)
        end


        fields[epic_link_field]  = parent if client_field_changed? :parent, epic_link_field
        if client_field_changed? :story_size, story_points_field
          fields[story_points_field]  = story_size.to_f.prettify
        end

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

      def self.find_by_attributes(project_id, attributes = {})
        search_by_attribute(self.find_all(project_id), attributes)
      end

      def self.find_by_id(project_id, id)
        self.find_all(project_id).find { |ticket| ticket.id == id }
      end

      def self.find_all(project_id)
        jql_query_string = "project = #{project_id} AND issuetype in (Epic, Story)"
        issues = jira_client.Issue.jql(jql_query_string, :max_results => 1000)
        issues.map do |ticket|
          self.new ticket
        end
      end


      def self.createmeta(project_id)
        project = jira_client.Project.find(project_id)
        project.createmeta
      end

      def comment(*options)
        nil
      end

      def destroy
        client_issue.delete
      end

      private
      def client_field_changed?(public_field, client_field = nil)
        client_field = public_field if client_field.nil?
        client_issue.send(client_field) != send(public_field)
      end


      def client_issue
        @system_data[:client]
      end

    end

  end
end

class Float
  def prettify
    to_i == self ? to_i : self
  end
end
