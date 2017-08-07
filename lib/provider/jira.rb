require 'uri'
require 'jira-ruby'

module TaskMapper::Provider
  # This is the Jira Provider for taskmapper

  module JiraAccessor

    def jira_client
      Thread.current["TaskMapper::Provider::JiraAccessor.jira"]
    end

    def jira_client=(jira_client)
      Thread.current["TaskMapper::Provider::JiraAccessor.jira"] = jira_client
    end

    def jira_project_metadata(project)
      Thread.current["TaskMapper::Provider::JiraAccessor.jira_project_metadata.#{project.key}-#{project.id}"]
    end

    def jira_project_metadata=(jira_project_metadata)
      project = jira_project_metadata.project
      Thread.current["TaskMapper::Provider::JiraAccessor.jira_project_metadata.#{project.key}-#{project.id}"] = jira_project_metadata
    end

  end

  module Jira
    include TaskMapper::Provider::Base

    #TICKET_API = Jira::Ticket # The class to access the api's tickets
    #PROJECT_API = Jira::Project # The class to access the api's projects
    
    # This is for cases when you want to instantiate using TaskMapper::Provider::Jira.new(auth)
    def self.new(auth = {})
      TaskMapper.new(:jira, auth)
    end
    
    # Providers must define an authorize method. This is used to initialize and set authentication
    # parameters to access the API
    def authorize(auth = {})
      # logger.debug { "start jira auth" }
      @authentication ||= TaskMapper::Authenticator.new(auth)

      #uri = URI.parse('https://cardboard.atlassian.net/') #@authentication.url)
      context_path = '' #uri.path != '/' ? uri.path : ''

      options = {
          :username => 'cardboardmain@gmail.com', #@authentication.username,
          :password => 'Post33Note@!', #@authentication.password,
          :site     => 'https://cardboard.atlassian.net/:443', # "#{uri.scheme}://#{uri.host}:#{uri.port}",
          :context_path => context_path,
          :auth_type => :basic,
          :use_ssl => true #uri.scheme.downcase == 'https'
      }

      self.jira_client = JIRA::Client.new(options)
      # begin
      #   user = self.jira_client.User.build
        # logger.debug { "before user.myself" }
        # user.myself
        @valid_auth = true
      # rescue
      #   # logger.debug { "jira auth failed" }
      #   @valid_auth = false
      # end
      # Set authentication parameters for whatever you're using to access the API
    end

    # Tad bit of a hack to get the inheritance down
    def jira_client
      Thread.current["TaskMapper::Provider::JiraAccessor.jira"]
    end

    def jira_client=(jira_client)
      Thread.current["TaskMapper::Provider::JiraAccessor.jira"] = jira_client
    end

    # declare needed overloaded methods here

    def valid?
      @valid_auth
    end

  end
end


