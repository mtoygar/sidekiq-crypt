ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
$TESTING = true

require 'sidekiq/cli'
require 'sidekiq/manager'
require 'sidekiq'
require 'logger'

# hides sidekiq retry errors
Sidekiq.logger.level = Logger::ERROR unless ENV['DEBUG']
