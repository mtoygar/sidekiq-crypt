module Sidekiq
  module Crypt
    class ServerMiddleware
      def initialize(opts = {})
        configuration = opts[:configuration]

        @traverser = Traverser.new(configuration)
        @decryption_cipher = configuration.decryption_class
      end

      def call(worker_class, job, queue, redis_pool = {})
        @iv = @decryption_cipher.read_iv_from_redis(job['jid'])
        @traverser.traverse!(job['args'], decryption_proc)

        yield
      end

      private

      def decryption_proc
        Proc.new { |param| @decryption_cipher.call(param, @iv) }
      end
    end
  end
end
