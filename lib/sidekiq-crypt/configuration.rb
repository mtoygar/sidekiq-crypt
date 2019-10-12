require 'sidekiq-crypt/default_cipher'

module Sidekiq
  module Crypt
    class Configuration
      attr_reader :encryption_class, :decryption_class, :filters

      def initialize(options = {})
        @encryption_class = DefaultCipher::Encrypt
        @decryption_class = DefaultCipher::Decrypt
        @filters = []

        include_rails_filter_parameters(options)
      end

      private

      def include_rails_filter_parameters(options)
        return unless defined?(::Rails) && (options[:include_rails_filters] || true)

        @filters = ::Rails.application.config.filter_parameters
      end
    end
  end
end
