# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path(__FILE__)

require 'sidekiq-crypt'
require 'sidekiq'

require 'minitest/autorun'
require 'dummy-app/config/environment'
require 'helpers/test_jobs'

module Sidekiq
  module Crypt
    class TestCase < Minitest::Test
      def setup
        super
        flush_redis
        reset_configured_filters
      end

      private

      def flush_redis
        Sidekiq.redis(&:flushall)
        sleep 0.05
      end

      def reset_configured_filters
        Sidekiq::Crypt.configuration.filters.map! { |_filter| [] }.flatten!
      end

      def configure_sidekiq_crypt(filters: [/^secret.*/], options: config_key_attrs)
        Sidekiq::Crypt.configure do |config|
          config.current_key_version = options[:current_key_version]
          config.key_store = options[:key_store]
          config.filters << filters
        end
      end

      def config_key_attrs
        { current_key_version: 'V1', key_store: { V1: ENV['CIPHER_KEY'] } }
      end
    end
  end
end
