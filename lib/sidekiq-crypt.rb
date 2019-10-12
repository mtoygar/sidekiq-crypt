require "sidekiq-crypt/version"
require 'sidekiq-crypt/configuration'

module Sidekiq
  module Crypt
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration) if block_given?
      end
    end
  end
end
