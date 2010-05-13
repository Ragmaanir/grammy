
gem 'rspec'

require 'Grammy'

# require custom matchers
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
