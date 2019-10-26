require 'sidekiq-crypt/traverser'

module Sidekiq
  module Crypt
    class ClientMiddleware
      def initialize(opts = {})
        configuration = opts[:configuration]

        @traverser = Traverser.new(configuration)
        @encryption_cipher = configuration.encryption_class
        @iv = @encryption_cipher.random_iv
      end

      def call(worker_class, job, queue, redis_pool)
        @traverser.traverse!(job['args'], encryption_proc)
        @encryption_cipher.write_encryption_header_to_redis(job['jid'], @iv)

        yield
      end

      private

      def encryption_proc
        Proc.new { |param| @encryption_cipher.call(param, @iv) }
      end
    end
  end
end
