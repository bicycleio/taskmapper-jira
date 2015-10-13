# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require './lib/jira/version'

Gem::Specification.new do |s|
  s.name          = 'taskmapper-jira'
  s.version       = TaskMapper::Jira::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Charles Lowell", "Rafael George", 'Peter Schwarz']
  s.email         = ["cowboyd@thefrontside.net", "rafael@hybridgroup.com", "peter.schwarz@bicycle.io"]
  s.homepage      = 'http://github.com/hybridgroup/taskmapper-jira'
  s.summary       = %q{taskmapper binding for JIRA}
  s.description   = %q{Interact with Atlassian JIRA ticketing system from Ruby}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
  # spec.add_runtime_dependency "taskmapper", "~> 1.0.2"
  # spec.add_runtime_dependency "jira-ruby", "~> 0.1.14"
  s.add_runtime_dependency(%q<taskmapper>, [">= 0"])
  s.add_runtime_dependency(%q<jira-ruby>, [">= 0"])
  s.add_development_dependency(%q<rspec>, ["~> 2.3"])
  s.add_development_dependency(%q<simplecov>, ["~> 0.5"])
  s.add_development_dependency(%q<rcov>, ["~> 1.0"])
end
