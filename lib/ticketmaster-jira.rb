require 'ticketmaster'
require 'jira4r'

%w{ jira ticket project comment }.each do |f|
  require File.dirname(__FILE__) + '/provider/' + f + '.rb';
end
