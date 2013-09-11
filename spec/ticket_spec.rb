require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TaskMapper::Provider::Jira::Ticket do 
  let(:url) { 'http://jira.atlassian.com' }
  let(:tm) {  TaskMapper.new(:jira, :username => 'testuser', :password => 'testuser', :url => url) }
  let(:project_from_jira) { create_project('PRO', 'project', 'project description', [ticket_from_jira]) }
  let(:fake_jira) { create_jira([project_from_jira]) }
  let(:ticket_from_jira) { create_ticket(ticket_id) }
  let(:ticket_class) { TaskMapper::Provider::Jira::Ticket }
  let(:project_from_tm) { tm.project 'PRO' }
  let(:ticket_id) { 'PRO-1' }
    
  before(:each) do
    override_jira('testuser', 'testuser', url, fake_jira)
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
