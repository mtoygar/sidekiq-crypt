require 'sidekiq-crypt/traverser'
require 'set'

module Sidekiq
  module Crypt
    class ClientMiddleware
      def initialize(opts = {})
        configuration = opts[:configuration]

        @traverser = Traverser.new(configuration.filters)
        @encrypted_keys = Set.new
      end

      def call(worker_class, job, queue, redis_pool)
        @iv = DefaultCipher::Encrypt.random_iv
        @traverser.traverse!(job['args'], encryption_proc)
        DefaultCipher::Encrypt.write_encryption_header_to_redis(job['jid'], @encrypted_keys, @iv)

        yield
      end

      private

      def encryption_proc
        Proc.new do |key, param|
          @encrypted_keys << key
          DefaultCipher::Encrypt.call(param, @iv)
        end
      end
    end
  end
end
