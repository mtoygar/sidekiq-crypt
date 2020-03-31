require_relative "sidekiq-crypt/version"
require_relative 'sidekiq-crypt/configuration'
require_relative 'sidekiq-crypt/default_cipher'
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
    end
  end
end
