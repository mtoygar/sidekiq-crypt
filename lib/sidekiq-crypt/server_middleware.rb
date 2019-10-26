module Sidekiq
  module Crypt
    class ServerMiddleware
      FILTERED = '[FILTERED]'.freeze

      def initialize(opts = {})
        configuration = opts[:configuration]

        @traverser = Traverser.new(configuration)
        @decryption_cipher = configuration.decryption_class
      end

      def call(worker_class, job, queue, redis_pool = {})
        @iv = @decryption_cipher.read_iv_from_redis(job['jid'])
        @traverser.traverse!(job['args'], decryption_proc)

        yield
      rescue => error
        filter_proc = Proc.new { |param| param = FILTERED }
        @traverser.traverse!(job['args'], filter_proc)

        raise error
      end

      private

      def decryption_proc
        Proc.new { |param| @decryption_cipher.call(param, @iv) }
      end
    end
  end
end
