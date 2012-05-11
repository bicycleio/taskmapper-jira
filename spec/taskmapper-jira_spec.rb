require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TaskMapper::Provider::Jira" do 
  before(:each) do
    @url = "some_url"
    @fj = FakeJiraTool.new
    Jira4R::JiraTool.stub!(:new).with(2, @url).and_return(@fj)
    @tm = TaskMapper.new(:jira, :username => 'testing', :password => 'testing', :url => @url)
  end

  it "should be able to instantiate a new taskmapper instance" do
    @tm.should be_an_instance_of(TaskMapper)
    @tm.should be_a_kind_of(TaskMapper::Provider::Jira)
  end

  it "should validate authentication with the valid method" do
    @tm.valid?.should be_true
  end
end
