# frozen_string_literal: true

module Sidekiq
  module Crypt
    class Configuration
      attr_accessor :filters, :current_key_version
      attr_reader :key_store

      def initialize(options = {})
        @filters = []
        @current_key_version = options.fetch(:current_key_version, nil)
        @key_store = options.fetch(:key_store, {}).transform_keys(&:to_s)

        include_rails_filter_parameters(options[:exclude_rails_filters])
      end

      def current_key
        key_store[current_key_version]
      end

      def key_by_version(given_key)
        key_store[given_key]
      end

      def key_store=(key_store_hash)
        @key_store = (key_store_hash || {}).transform_keys(&:to_s)
      end

      private

      def include_rails_filter_parameters(exclude_rails_filters)
        return unless defined?(::Rails)
        return if exclude_rails_filters

        @filters = ::Rails.application.config.filter_parameters
      end
    end
  end
end
