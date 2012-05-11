module TaskMapper::Provider
  # This is the Jira Provider for taskmapper
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
      @authentication ||= TaskMapper::Authenticator.new(auth)
      $jira = Jira4R::JiraTool.new(2,@authentication.url)
      begin 
        $jira.login(@authentication.username, @authentication.password)
        @valid_auth = true
      rescue
        @valid_auth = false
      end
      # Set authentication parameters for whatever you're using to access the API
    end

    # declare needed overloaded methods here

    def project(*options)
      if options.first.is_a? String
        options[0] = options[0].to_i
      end
      if options.first.is_a? Fixnum
        Project.find_by_id(options.first)
      elsif options.first.is_a? Hash
        Project.find_by_attributes(options.first).first
      end
    end

    def projects(*options)
      Project.find(options)
    end

    def valid?
      @valid_auth
    end
  end
end


