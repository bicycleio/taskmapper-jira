require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TaskMapper::Provider::Jira::Ticket do 
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
  let(:tm) {  TaskMapper.new(:jira, :username => 'testuser', :password => 'testuser', :url => url) }
  let(:ticket_class) { TaskMapper::Provider::Jira::Ticket }
  let(:project_from_tm) { tm.project 1 }
  let(:ticket_id) { 1 }
    
  before(:each) do
    Jira4R::JiraTool.stub!(:new).with(2, url).and_return(fake_jira)
    fake_jira.stub!(:getProjectsNoSchemes).and_return([project_from_jira, project_from_jira])
    fake_jira.stub!(:getProjectById).and_return(project_from_jira)
    fake_jira.stub!(:getIssuesFromJqlSearch).and_return([ticket_from_jira])
  end

  describe "Retrieving tickets" do 
    context "when #tickets" do 
      subject { project_from_tm.tickets } 
      it { should be_an_instance_of Array }

      context "when #tickets.first" do 
        subject { project_from_tm.tickets.first } 
        it { should be_an_instance_of ticket_class }
      end
    end

    context "when #tickets with array of id's" do 
      subject { project_from_tm.tickets [ticket_id] } 
      it { should be_an_instance_of Array }
    end

    context "when #tickets with attributes" do 
      subject { project_from_tm.tickets :id => ticket_id } 
      it { should be_an_instance_of Array }
    end

    describe "Retrieve a single ticket" do 
      context "when #ticket with id" do 
        subject { project_from_tm.ticket ticket_id } 
        it { should be_an_instance_of ticket_class }
      end

      context "when #ticket with attribute" do 
        subject { project_from_tm.ticket :id => ticket_id } 
        it { should be_an_instance_of ticket_class }
      end
    end
  end

end
