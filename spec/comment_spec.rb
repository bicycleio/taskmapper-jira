require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TaskMapper::Provider::Jira::Comment do
  let(:url) { 'http://jira.atlassian.com' }
  let(:fake_jira) { FakeJiraTool.new }
  let(:project_from_jira) { Struct.new(:id, :name, :description).new(1, 'project', 'project description') }
  let(:ticket_from_jira) do 
              Struct.new(:id, 
                         :status, 
                         :priority, 
                         :summary, 
                         :resolution, 
                         :created, 
                         :updated, 
                         :description, :assignee, :reporter).new(1,'open','high', 'ticket 1', 'none', Time.now, Time.now, 'description', 'myself', 'yourself')
  end
  let(:comment_from_jira) do
            Struct.new(:id, :author, :body, :created, :updated, :ticket_id, :project_id).new(1,'myself','body',Time.now,Time.now,1,1)
  end
  let(:tm) { TaskMapper.new :jira, :username => 'soaptester', :password => 'soaptester', :url => url }
  let(:ticket) { tm.project(1).ticket(1) }
  let(:comment_class) { TaskMapper::Provider::Jira::Comment }
  let(:comment_id) { 1 }
  before(:each) do
    Jira4R::JiraTool.stub!(:new).with(2, url).and_return(fake_jira)
    fake_jira.stub!(:getProjectsNoSchemes).and_return([project_from_jira, project_from_jira])
    fake_jira.stub!(:getProjectById).and_return(project_from_jira)
    fake_jira.stub!(:getIssuesFromJqlSearch).and_return([ticket_from_jira])
    fake_jira.stub!(:getComments).and_return([comment_from_jira])
  end

  describe "Retrieving comments" do 
    context "when #comments" do 
      subject { ticket.comments } 
      it { should be_an_instance_of Array }

      context "when #comments.first" do 
        subject { ticket.comments.first } 
        it { should be_an_instance_of comment_class }
      end
    end

    context "when #comments with id's" do 
      subject { ticket.comments [comment_id] }
      it { should be_an_instance_of Array }
    end

  end
end
