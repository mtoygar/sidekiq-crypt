require "sidekiq-crypt/version"
require 'sidekiq-crypt/configuration'
require 'sidekiq-crypt/client_middleware'
require 'sidekiq-crypt/server_middleware'

module Sidekiq
  module Crypt
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration) if block_given?

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
            chain.add Sidekiq::Crypt::ServerMiddleware, configuration: configuration
          end
        end
      end
    end
  end
end
