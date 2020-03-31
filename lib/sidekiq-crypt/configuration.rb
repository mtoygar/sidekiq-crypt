module Sidekiq
  module Crypt
    class Configuration
      attr_reader :filters

      def initialize(options = {})
        @filters = []

        include_rails_filter_parameters(options)
      end

      private

      def include_rails_filter_parameters(options)
        return unless defined?(::Rails)
        return if options[:exclude_rails_filters]

        @filters = ::Rails.application.config.filter_parameters
      end
    end
  end
end
