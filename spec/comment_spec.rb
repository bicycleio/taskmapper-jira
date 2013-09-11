require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TaskMapper::Provider::Jira::Comment do
  let(:url) { 'http://jira.atlassian.com' }
  let(:tm) {  TaskMapper.new(:jira, :username => 'testuser', :password => 'testuser', :url => url) }
  let(:project_from_jira) { create_project('PRO', 'project', 'project description', [ticket_from_jira]) }
  let(:fake_jira) { create_jira([project_from_jira]) }
  let(:project_from_tm) { tm.project 'PRO' }
  let(:ticket_from_jira) { create_ticket(ticket_id) }
  let(:ticket_class) { TaskMapper::Provider::Jira::Ticket }
  let(:ticket_id) { 'PRO-1' }
  let(:ticket) {project_from_tm.ticket(ticket_id)}

  let(:comment_from_jira) do
    Struct.new(:id, :author, :body, :created, :updated, :ticket_id, :project_id).new(1,'myself','body',Time.now,Time.now,1,1)
  end
  let(:comment_class) { TaskMapper::Provider::Jira::Comment }
  let(:comment_id) { 1 }

  before(:each) do
    override_jira('testuser', 'testuser', url, fake_jira)
  end

  describe "Retrieving comments" do
    context "when #comments" do
      subject { ticket.comments }
      it { should be_an_instance_of Array }

      context "when #comments.first" do
        subject { ticket.comments.first }
        pending { should be_an_instance_of comment_class }
      end
    end

    context "when #comments with id's" do 
      subject { ticket.comments [comment_id] }
      it { should be_an_instance_of Array }
    end

  end
end
