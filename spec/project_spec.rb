require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TaskMapper::Provider::Jira::Project do 

  let(:backend_url) { 'http://jira.atlassian.com' }
  let(:tm) { TaskMapper.new(:jira, :username => 'soaptester', :password => 'soaptester', :url => backend_url) }
  let(:fake_jira) { FakeJiraTool.new }
  let(:returned_project) { Struct.new(:id, :name, :description).new(1, 'project', 'project description') }
  let(:project_class) { TaskMapper::Provider::Jira::Project }
  let(:project_id) { 1 }
  before(:each) do
    Jira4R::JiraTool.stub!(:new).with(2, backend_url).and_return(fake_jira)
    fake_jira.stub!(:getProjectsNoSchemes).and_return([returned_project, returned_project])
    fake_jira.stub!(:getProjectByKey).and_return(returned_project)
  end

  describe "Retrieving projects" do 
    context "when #projects" do 
      subject { tm.projects } 
      pending { should be_an_instance_of Array }
    end

    context "when #projects with array of id's" do 
      subject { tm.projects [project_id] }
      it { should be_an_instance_of Array }
    end

    context "when #projects with attributes" do 
      subject { tm.projects :id => project_id }
      it { should be_an_instance_of Array }
    end

    describe "Retrieving a single project" do 
      context "when #project with id" do 
        subject { tm.project project_id } 
        it { should be_an_instance_of project_class } 

        context "when #project.name" do 
          subject { tm.project(project_id).name } 
          it { should_not be_nil } 
          it { should be_eql('project') } 
        end
      end

      context "when #project with attribute" do 
        subject { tm.project :id => project_id } 
        it { should be_an_instance_of project_class }
      end
    end
  end
end
