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
        @iv = Cipher.random_iv
        @traverser.traverse!(job['args'], encryption_proc)
        write_encryption_header_to_redis(job['jid'], @encrypted_keys, @iv)

        yield
      end

      private

      def write_encryption_header_to_redis(job_id, encrypted_keys, iv)
        Sidekiq.redis do |conn|
          conn.set(
            "sidekiq-crpyt-header:#{job_id}",
            JSON.generate(
              nonce: Base64.encode64(iv),
              encrypted_keys: encrypted_keys.to_a,
              key_version: Sidekiq::Crypt.configuration.current_key_version
            )
          )
        end
      end

      def encryption_proc
        Proc.new do |key, param|
          @encrypted_keys << key
          Cipher.encrypt(param, @iv)
        end
      end
    end
  end
end
