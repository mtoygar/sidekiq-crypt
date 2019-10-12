module Sidekiq
  module Crypt
    class ClientMiddleware
      def initialize(opts = {})
        configuration = opts[:configuration]
        @encryption_cipher = configuration.encryption_class
        @iv = @encryption_cipher.random_iv
      end

      def encryption_proc
        # later traverse job arguments and encrypt the filtered once.
        Proc.new do |job, iv|
          job["args"][1]["card_number"] = @encryption_cipher.call(job["args"][1]["card_number"], iv)
        end
      end

      def call(worker_class, job, queue, redis_pool)
        encryption_proc.call(job, @iv)
        @encryption_cipher.write_encryption_header_to_redis(job['jid'], @iv)

        yield
      end
    end
  end
end
