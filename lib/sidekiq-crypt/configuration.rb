require 'sidekiq-crypt/default_cipher'

module Sidekiq
  module Crypt
    class Configuration
      attr_reader :encryption_class, :decryption_class, :filters

      def initialize(options = {})
        @encryption_class = DefaultCipher::Encrypt
        @decryption_class = DefaultCipher::Decrypt
        @filters = []
      end
    end
  end
end
