require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TaskMapper::Provider::Jira" do
  before(:each) do
    @url = "https://someurl:8090/myjira"
    @mockJira = double('JiraClient')

    mockProject = double("Project")
    mockProject.stub(:all)

    @mockJira.stub(:Project).and_return(mockProject)

    JIRA::Client.stub(:new).with({
        :username => 'testing',
        :password => 'testing',
        :site => 'https://someurl:8090',
        :context_path => '/myjira',
        :auth_type => :basic,
        :use_ssl => true
    }).and_return(@mockJira)

    @tm = TaskMapper.new(:jira, :username => 'testing', :password => 'testing', :url => @url)
  end

  it "should be able to instantiate a new taskmapper instance" do
    @tm.should be_an_instance_of(TaskMapper)
    @tm.should be_a_kind_of(TaskMapper::Provider::Jira)
  end

  it "should validate authentication with the valid method" do
    @tm.valid?.should be true
  end
end
