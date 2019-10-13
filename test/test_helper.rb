$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "sidekiq-crypt"
require 'sidekiq'

require "minitest/autorun"

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

