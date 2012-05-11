module TaskMapper::Provider
  module Jira
    # Project class for taskmapper-jira
    #
    #
    class Project < TaskMapper::Provider::Base::Project
      #API = Jira::Project # The class to access the api's projects
      # declare needed overloaded methods here
      # copy from this.copy(that) copies that into this
      def initialize(*object)
        if object.first
          object = object.first
          unless object.is_a? Hash
            @system_data = {:client => object}
            hash = {:id => object.id.to_i, 
                    :name => object.name,
                    :description => object.description,
                    :updated_at => nil,
                    :created_at => nil}
          else
            hash = object
          end
          super(hash)
        end
      end

      def id
        self[:id].to_i
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

      def self.find(*options)
        if options[0].first.is_a? Array
          self.find_all.select do |project| 
            project if options.first.any? { |id| project.id == id }
          end
        elsif options[0].first.is_a? Hash
          find_by_attributes(options[0].first)
        else
          self.find_all
        end
      end

      def self.find_by_attributes(attributes = {})
        search_by_attribute(self.find_all, attributes)
      end

      def self.find_all
        $jira.getProjectsNoSchemes().map do |project| 
          Project.new project 
        end
      end

      def self.find_by_id(id)
        self.find_all.select { |project| project.id == id }.first
      end

    end
  end
end


