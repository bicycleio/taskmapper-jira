module TaskMapper::Provider
  module Jira
    # Ticket class for taskmapper-jira
    #
    
    class Ticket < TaskMapper::Provider::Base::Ticket
      #API = Jira::Ticket # The class to access the api's tickets
      # declare needed overloaded methods here
      def initialize(*object)
        if object.first
          object = object.first
          unless object.is_a? Hash
            @system_data = {:client => object}
            hash = {:id => object.id.to_i, 
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

      def id
        self[:id].to_i
      end

      def updated_at
        normalize_datetime(self[:updated_at])
      end

      def created_at
        normalize_datetime(self[:created_at])
      end

      def self.find_by_attributes(project_id, attributes = {})
        search_by_attribute(self.find_all(project_id), attributes)
      end

      def self.find_by_id(project_id, id)
        self.find_all(project_id).find { |ticket| ticket.id == id }
      end

      def self.find_all(project_id)
        $jira.getIssuesFromJqlSearch("project = #{project_id}", 200).map do |ticket|
          self.new ticket
        end
      end

      def comments(*options)
        Comment.find(self.id, options)
      end

      def comment(*options)
        nil
      end
      
      private
      def normalize_datetime(datetime)
        Time.mktime(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)
      end

   end

  end
end
