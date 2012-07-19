module TaskMapper::Provider
  module Jira
    # The comment class for taskmapper-jira
    #
    # Do any mapping between taskmapper and your system's comment model here
    # versions of the ticket.
    #
    class Comment < TaskMapper::Provider::Base::Comment
      #API = Jira::Comment # The class to access the api's comments
      # declare needed overloaded methods here
      
      def initialize(*object)
        if object.first
          object = object.first
          unless object.is_a? Hash
            @system_data = {:client => object}
            hash = {:id => object.id, 
              :author => object.author,
              :body => object.body,
              :created_at => object.created,
              :updated_at => object.updated,
              :ticket_id => object.ticket_id,
              :project_id => object.project_id}
          else
            hash = object
          end
          super(hash)
        end
      end

      def self.find_all(ticket_id)
        begin 
          $jira.getComments("#{ticket_id}").map { |comment| self.new comment }
        rescue
          []
        end
      end

      def self.find_by_attributes(project_id, ticket_id, attributes = {}) 
        search_by_attribute(self.find_all(ticket_id), attributes)
      end

      def self.find_by_id(project_id, ticket_id, id) 
        self.find_all(ticket_id).find { |comment| comment.id == id }
      end
    end
  end
end
