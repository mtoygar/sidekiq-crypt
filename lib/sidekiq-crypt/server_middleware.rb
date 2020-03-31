module Sidekiq
  module Crypt
    class ServerMiddleware
      FILTERED = '[FILTERED]'.freeze

      def call(worker_class, job, queue, redis_pool = {})
        @encryption_header = DefaultCipher::Decrypt.read_encryption_header_from_redis(job['jid'])
        Traverser.new(@encryption_header[:encrypted_keys]).traverse!(job['args'], decryption_proc)

        yield
      rescue => error
        Traverser.new(@encryption_header[:encrypted_keys]).traverse!(job['args'], filter_proc)

        raise error
      end

      private

      def decryption_proc
        Proc.new { |_key, param| DefaultCipher::Decrypt.call(param, @encryption_header[:iv]) }
      end

      def filter_proc
        Proc.new { |_key, param| param = FILTERED }
      end
    end
  end
end
