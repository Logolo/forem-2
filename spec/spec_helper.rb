# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'factory_girl'
require 'fabrication'
require 'database_cleaner'

# for some reason Fabrication is not auto-loading these
require File.expand_path("../fabricators/category_fabricator.rb",  __FILE__)
require File.expand_path("../fabricators/forum_fabricator.rb",  __FILE__)
require File.expand_path("../fabricators/post_fabricator.rb",  __FILE__)
require File.expand_path("../fabricators/topic_fabricator.rb",  __FILE__)
require File.expand_path("../fabricators/user_fabricator.rb",  __FILE__)

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

RSpec.configure do |config|
  #config.use_transactional_fixtures = false
  config.include(MailerMacros)
  config.before(:each) { reset_email }

  config.include Devise::TestHelpers, :type => :controller

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
