ENV["RAILS_ENV"] = "test"
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift File.expand_path(__FILE__)

require "sidekiq-crypt"
require 'sidekiq'

require "minitest/autorun"
require "dummy-app/config/environment"
require "rails/test_help"

# ENV['DATABASE_URL'] = 'sqlite3://localhost/:memory:'

# minitest 4 is required for rails4 and does not implement Minitest::Test
if defined?(Minitest::Test)
  class Sidekiq::Crypt::TestCase < Minitest::Test
    def setup
      flush_redis
      super
    end

    private

    def flush_redis
      Sidekiq.redis { |conn| conn.flushall }
      sleep 0.05
    end
  end
else
  class Sidekiq::Crypt::TestCase < Minitest::Unit
    def setup
      flush_redis
      super
    end

    private

    def flush_redis
      Sidekiq.redis { |conn| conn.flushall }
      sleep 0.05
    end
  end
end
