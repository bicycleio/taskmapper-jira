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

            if object.issuetype.name.downcase == 'epic'
              @description = object.description
              @title = object.customfield_10009
            else
              @title = object.summary
              @description = object.description
            end
            
            story_size = object.customfield_10004
            story_size = story_size.prettify.to_s unless story_size.nil?
            
            hash = {:id => object.key,
              :status => object.status,
              :priority => object.priority,
              :issuetype => object.issuetype.name.downcase,
              :parent => object.customfield_10008, #default
              :title => @title,
              :resolution => object.resolution,
              :created_at => object.created,
              :updated_at => object.updated,
              :description => @description,
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


        if options.key? :issuetype
          type = issuetypes.find {|t| t.name.downcase == options[:issuetype] }
        else
          type = issuetypes.find {|t| t.name == 'Story' or t.name == 'New Feature'}
        end

        type = issuetypes.first unless type

        new_issue = jira_client.Issue.build

        fields = {:project => {:key => options[:project_id]}}

        fields[:issuetype] = {:id => type.id} if type

        if type.name.downcase == 'epic'
          fields[:customfield_10009]  = options[:title] #if options.key? :title
          fields[:summary] = options[:title]     
          if options.key? :description
            fields[:description] = options[:description] 
          end

        else
          fields[:summary] = options[:title] if options.key? :title
          fields[:description] = options[:description] if options.key? :description
        end
        
        # fields[:summary] = options[:title] if options.key? :title
        # fields[:description] = options[:description] if options.key? :description
        fields[:customfield_10008]  = options[:parent] if options.key? :parent
        fields[:customfield_10004]  = options[:story_size] if options.key? :story_size



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

          
        #   available_transitions = jira_client.Transition.all(:issue => new_issue)
        #   p available_transitions
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

        if self.issuetype == "epic"
          fields[:customfield_10009] = title if client_field_changed?(:title, :customfield_10009)
          fields[:description] =  description if client_field_changed?(:description)
        else
          fields[:summary] = title if client_field_changed?(:title, :summary)
          fields[:description] =  description if client_field_changed?(:description)
        end

        fields[:customfield_10008]  = parent if client_field_changed? :parent, :customfield_10008
        fields[:customfield_10004]  = story_size if client_field_changed? :story_size, :customfield_10004


        update_status = client_status = nil
        if self.key? :transition
            if self[:transition].is_a? String
              update_status = self[:transition].parameterize.underscore.to_sym
            else 
            # update_status = self[:status].try {|name| name.parameterize.underscore.to_sym}
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
        project = jira_client.Project.find(project_id)

        # This is currently a magic number situation, anything over
        # 1000 and we're going to run into trouble.
        project.issues.map do |ticket|
          ticket.fetch
          self.new ticket
        end
      end


      def comment(*options)
        nil
      end

      def destroy
        client_issue.delete
      end

      private
      # def normalize_datetime(datetime)
      #   Time.mktime(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)
      # end

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