module TaskMapper::Provider
  module Jira
    # Project class for taskmapper-jira
    #
    #
    class Project < TaskMapper::Provider::Base::Project
      extend TaskMapper::Provider::JiraAccessor
      #API = Jira::Project # The class to access the api's projects
      # declare needed overloaded methods here
      # copy from this.copy(that) copies that into this
      def initialize(*object)
        if object.first
          object = object.first
          unless object.is_a? Hash
            @system_data = {:client => object}
            hash = {:id => object.key,
                    :name => object.name,
                    # :description => object.description,
                    :updated_at => nil,
                    :created_at => nil}
          else
            hash = object
          end
          super(hash)
        end
      end

      def copy(project)
        project.tickets.each do |ticket|
          copy_ticket = self.ticket!(:title => ticket.title, :description => ticket.description)
          ticket.comments.each do |comment|
            copy_ticket.comment!(:body => comment.body)
            sleep 1
          end
        end
      end

      def self.find_by_attributes(attributes = {})
        search_by_attribute(self.find_all, attributes)
      end

      def self.find_all
        projects = jira_client.Project.all
        projects.each do |project|
          # project.fetch
          p 'individual project'
          p project
          Project.new project
        end
      end

      def self.find_by_id(id)
        project = jira_client.Project.find(id)
        Project.new project unless project.nil?
      end

    end
  end
end


