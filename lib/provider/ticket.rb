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
              :estimate => object.timeestimate,
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

      def status
        self[:status].name.try {|name| name.parameterize.underscore.to_sym}
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
        type = issuetypes.find {|t| t.name == 'Story' or t.name == 'New Feature'}
        type = issuetypes.first unless type

        new_issue = jira_client.Issue.build

        fields = {:project => {:key => options[:project_id]}}

        fields[:issuetype] = {:id => type.id} if type
        fields[:summary] = options[:title] if options.key? :title
        fields[:description] = options[:description] if options.key? :description

        begin
          new_issue.save!({:fields => fields})
          new_issue.fetch
        rescue JIRA::HTTPError => jira_error
          parsed_response = JSON.parse(jira_error.response.body) if jira_error.response.content_type.include?('application/json')
          the_errors = parsed_response['errors']
          msg = the_errors.values.join('/n')

          raise TaskMapper::Exception.new(msg)
        end

        Ticket.new new_issue
      end

      def save
        fields = {}
        fields[:summary] = title if client_field_changed?(:title, :summary)
        fields[:description]=  description if client_field_changed?(:description)

        client_issue.save({:fields => fields})
        client_issue.fetch

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
        project.issues(:maxResults => 1000).map do |ticket|
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
      def normalize_datetime(datetime)
        Time.mktime(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)
      end

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
