require_relative "sidekiq-crypt/version"
require_relative 'sidekiq-crypt/configuration'
require_relative 'sidekiq-crypt/cipher'
require_relative 'sidekiq-crypt/client_middleware'
require_relative 'sidekiq-crypt/server_middleware'

module Sidekiq
  module Crypt
    class << self
      attr_reader :configuration

      def configuration(options = {})
        @configuration ||= Configuration.new(options)
      end

      def configure(options = {})
        yield(configuration(options)) if block_given?

        configuration.filters.flatten!
        raise 'you must specify at least one filter' if configuration.filters.empty?
        raise 'you must specify current key version' if configuration.current_key_version.blank?
        raise 'you must specify a hash for key store' if configuration.key_store.blank?
        raise "current_key_version can't be found in key_store" if configuration.current_key.nil?
        raise 'key is not valid' if invalid_key?

        inject_sidekiq_middlewares
      end

      def inject_sidekiq_middlewares
        ::Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.add Sidekiq::Crypt::ClientMiddleware, configuration: configuration
          end
        end

        ::Sidekiq.configure_server do |config|
          config.client_middleware do |chain|
            chain.add Sidekiq::Crypt::ClientMiddleware, configuration: configuration
          end

          config.server_middleware do |chain|
            chain.add Sidekiq::Crypt::ServerMiddleware
          end
        end
      end

      private

      def invalid_key?
        Sidekiq::Crypt::Cipher.encrypt('dummy_str', Sidekiq::Crypt::Cipher.random_iv)
        false
      rescue StandardError
        true
      end
    end
  end
end
