require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TaskMapper::Provider::Jira::Project do 

  let(:backend_url) { 'http://sampleserver' }

  let(:tm) { TaskMapper.new(:jira, :username => 'tester', :password => 'secret', :url => backend_url) }

  let(:mock_project) { create_project(project_id, 'project name', 'description') }

  let(:fakejira) { create_jira([mock_project]) }

  let(:project_id) { 'PRO' }
  let(:project_class) { TaskMapper::Provider::Jira::Project }

  before(:each) do
    override_jira('tester', 'secret', backend_url, fakejira)
  end

  describe "Retrieving projects" do 
    context "when #projects" do 
      subject { tm.projects } 
      it { should be_an_instance_of Array }
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
          it {
            should be_eql('project name')
          }
        end
      end

      context "when #project with attribute" do 
        subject { tm.project :id => project_id } 
        it { should be_an_instance_of project_class }
      end
    end
  end
end
