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
            hash = {:id => object.key,
              :status => object.status,
              :priority => object.priority,
              :title => object.summary,
              :resolution => object.resolution,
              :created_at => object.created,
              :updated_at => object.updated,
              :description => object.description,
              :assignee => object.assignee,
              :requestor => object.reporter}
          else
            hash = object
          end
          super(hash)
        end
      end

      def updated_at
        normalize_datetime(self[:updated_at])
      end

      def created_at
        normalize_datetime(self[:created_at])
      end


      def self.create(*options)
        options = options.first if options.is_a? Array

        issuetypes = jira_client.Issuetype.all

        type = issuetypes.find {|t| t.name == 'Story'}

        new_issue = jira_client.Issue.build

        fields = {:project => {:key => options[:project_id]}, :issuetype=> {:id => type.id}}

        fields[:summary] = options[:title] if options.key? :title
        fields[:description] = options[:description] if options.key? :description

        new_issue.save({:fields => fields})
        new_issue.fetch

        Ticket.new new_issue
      end

      def save

        fields = {}
        fields[:summary] = title if client_field_changed?(:title, :summary)
        fields[:description]=  description if client_field_changed?(:description)

        @system_data[:client].save({:fields => fields})
      end

      def self.find_by_attributes(project_id, attributes = {})
        search_by_attribute(self.find_all(project_id), attributes)
      end

      def self.find_by_id(project_id, id)
        self.find_all(project_id).find { |ticket| ticket.id == id }
      end

      def self.find_all(project_id)
        project = jira_client.Project.find(project_id)

        project.issues.map do |ticket|
          ticket.fetch
          self.new ticket
        end
      end

      def comment(*options)
        nil
      end
      
      private
      def normalize_datetime(datetime)
        Time.mktime(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)
      end

      def client_field_changed?(public_field, client_field = nil)
        client_field = public_field if client_field.nil?
        @system_data[:client].send(client_field) != send(public_field)
      end

   end

  end
end
