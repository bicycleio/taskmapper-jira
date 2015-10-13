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
    p.stub(:client).and_return(mock_jira)

    p.issues.each { |t|
      t.stub(:client).and_return(mock_jira)
    }
  }

  mock_jira
end

def issue_client
  @issue_client = double('IssueClient') if @issue_client.nil?
  @issue_client
end

def create_project(id, name, description, tickets = [], issue_types=[])
  project = double('Project')

  project.stub(:key).and_return(id)
  project.stub(:name).and_return(name)
  project.stub(:fetch)
  project.stub(:description).and_return(description)

  project.stub(:issues).and_return(tickets)
  project.stub(:issuetypes).and_return(issue_types)

  project
end

def create_ticket(key, status='open')

  ticket = double("Issue")
  ticket.stub(:key).and_return(key)
  ticket.stub(:status).and_return({:name => status})
  ticket.stub(:priority).and_return('high')
  ticket.stub(:summary).and_return('Ticket 1')
  ticket.stub(:resolution).and_return('none')
  ticket.stub(:created).and_return(Time.now)
  ticket.stub(:updated).and_return(Time.now)
  ticket.stub(:description).and_return('description')
  ticket.stub(:assignee).and_return('myself')
  ticket.stub(:reporter).and_return('yourself')
  ticket.stub(:timeestimate).and_return('1')
  ticket.stub(:fetch)
  ticket.stub(:comments)

  issue_client.stub(:find).with(key).and_return(ticket)

  ticket
end

def override_jira(username, password, url, fake_jira)
  options = {
      :username => username,
      :password => password,
      :site => url + ':80',
      :context_path => '',
      :auth_type => :basic,
      :use_ssl => false
  }

  fake_jira.stub(:options).and_return(options)
  JIRA::Client.stub(:new).with(options).and_return(fake_jira)

end

RSpec.configure do |config|
  config.color = true
end
