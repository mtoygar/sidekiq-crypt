# frozen_string_literal: true

require_relative 'sidekiq-crypt/version'
require_relative 'sidekiq-crypt/configuration'
require_relative 'sidekiq-crypt/cipher'
require_relative 'sidekiq-crypt/client_middleware'
require_relative 'sidekiq-crypt/server_middleware'
require_relative 'sidekiq-crypt/worker'

module Sidekiq
  module Crypt
    class << self
      def configuration(options = {})
        @configuration ||= Configuration.new(options)
      end

      def configure(options = {})
        yield(configuration(options)) if block_given?

        configuration.filters.flatten!
        validate_configuration!

        inject_sidekiq_middlewares
      end

      def inject_sidekiq_middlewares
        inject_client_middleware
        inject_server_middleware
      end

      private

      def inject_client_middleware
        ::Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.add Sidekiq::Crypt::ClientMiddleware, configuration: configuration
          end
        end
      end

      def inject_server_middleware
        ::Sidekiq.configure_server do |config|
          config.client_middleware do |chain|
            chain.add Sidekiq::Crypt::ClientMiddleware, configuration: configuration
          end

          config.server_middleware do |chain|
            chain.add Sidekiq::Crypt::ServerMiddleware
          end
        end
      end

      def validate_configuration!
        raise 'you must specify current key version' if configuration.current_key_version.blank?
        raise 'you must specify a hash for key store' if configuration.key_store.blank?
        raise "current_key_version can't be found in key_store" if configuration.current_key.nil?
        raise 'current key is not valid for encryption' if invalid_key?
      end

      def invalid_key?
        Sidekiq::Crypt::Cipher.encrypt('dummy_str', Sidekiq::Crypt::Cipher.random_iv)
        false
      rescue StandardError
        true
      end
    end
  end
end
