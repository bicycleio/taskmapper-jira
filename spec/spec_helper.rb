$:.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
require 'taskmapper'
require 'taskmapper-jira'
require 'rspec'
require 'rspec/expectations'

def create_jira(projects)
  mock_jira = double('Jira')

  project_client = double('ProjectClient')
  project_client.stub(:all).and_return(projects)

  mock_jira.stub(:Project).and_return(project_client)
  mock_jira.stub(:Issue).and_return(issue_client)

  issue_type = double('IssueType')
  issue_type.stub(:all).and_return([issue_type])
  issue_type.stub(:id).and_return(1)
  issue_type.stub(:name).and_return('Story')

  mock_jira.stub(:Issuetype).and_return(issue_type)


  projects.each {|p|
    project_client.stub(:find).with(p.key).and_return(p)
  }

  mock_jira
end

def issue_client
  @issue_client = double('IssueClient') if @issue_client.nil?

  @issue_client
end

def create_project(id, name, description, tickets = [])
  project = double('Project')

  project.stub(:key).and_return(id)
  project.stub(:name).and_return(name)
  project.stub(:fetch)
  project.stub(:description).and_return(description)

  project.stub(:issues).and_return(tickets)

  project
end

def create_ticket(key)

  ticket = Struct.new(:key,
                      :status,
                      :priority,
                      :summary,
                      :resolution,
                      :created,
                      :updated,
                      :description, :assignee, :reporter)
  .new(key, 'open', 'high', 'ticket 1', 'none', Time.now, Time.now, 'description', 'myself', 'yourself')

  ticket.stub(:fetch)

  issue_client.stub(:find).with(key).and_return(ticket)

  ticket
end

def override_jira(username, password, url, fakejira)
  JIRA::Client.stub(:new).with({
                                   :username => username,
                                   :password => password,
                                   :site => url + ':80',
                                   :context_path => '',
                                   :auth_type => :basic,
                                   :use_ssl => false
                               }).and_return(fakejira)

end

RSpec.configure do |config|
  config.color_enabled = true
end

