module Sidekiq
  module Crypt
    class ServerMiddleware
      def initialize(opts = {})
        configuration = opts[:configuration]
        @decryption_cipher = configuration.decryption_class
      end

      def decryption_proc
        # later traverse job arguments and decrypt the filtered ones.
        Proc.new do |job, iv|
          job["args"][1]["card_number"] = @decryption_cipher.call(job["args"][1]["card_number"], iv)
        end
      end

      def call(worker_class, job, queue, redis_pool = {})
        iv = @decryption_cipher.read_iv_from_redis(job['jid'])
        decryption_proc.call(job, iv)

        yield
      end
    end
  end
end
