require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TaskMapper::Provider::Jira::Project do 

  let(:tm) { TaskMapper.new(:jira, :username => 'soaptester', :password => 'soaptester', :url => 'http://jira.atlassian.com') }
  let(:project_class) { TaskMapper::Provider::Jira::Project }

  describe "Retrieving projects" do 
    before(:each) do 
    end

    context "when #projects" do 
      subject { tm.projects } 
      it { should be_an_instance_of Array }
    end
  end

  it "should be able to load all projects based on an array of id's" do 
    pending
    tm.projects([1]).should be_an_instance_of(Array)
    tm.projects.first.should be_an_instance_of(@klass)
    tm.projects.first.id.should == 1
  end

  it "should be load all projects based on attributes" do 
    pending
    projects = tm.projects(:id => 1)
    projects.should be_an_instance_of(Array)
    projects.first.should be_an_instance_of(@klass)
    projects.first.id.should == 1
  end

  it "should be able to load a single project based on id" do
    pending
    project = tm.project(1)
    project.should be_an_instance_of(@klass)
    project.name.should == 'project'
  end

  it "should be able to load a single project by attributes" do
    pending
    project = tm.project(:id => 1)
    project.should be_an_instance_of(@klass)
    project.name.should == 'project'
  end
end
