module Sidekiq
  module Crypt
    class ServerMiddleware
      FILTERED = '[FILTERED]'.freeze

      def call(worker_class, job, queue, redis_pool = {})
        @encryption_header = read_encryption_header_from_redis(job['jid'])
        Traverser.new(@encryption_header[:encrypted_keys]).traverse!(job['args'], decryption_proc)

        yield
      rescue => error
        Traverser.new(@encryption_header[:encrypted_keys]).traverse!(job['args'], filter_proc)

        raise error
      end

      private

      def decryption_proc
        Proc.new do |_key, param|
          Cipher.decrypt(param, @encryption_header[:iv], @encryption_header[:key_version])
        end
      end

      def filter_proc
        Proc.new { |_key, param| param = FILTERED }
      end

      def read_encryption_header_from_redis(job_id)
        parsed_header = JSON.parse(read_encryption_header(job_id))

        {
          iv: Base64.decode64(parsed_header['nonce']),
          encrypted_keys: parsed_header['encrypted_keys'],
          key_version: parsed_header['key_version']
        }
      end

      def read_encryption_header(job_id)
        Sidekiq.redis do |conn|
          header = conn.get("sidekiq-crpyt-header:#{job_id}")
          conn.del("sidekiq-crpyt-header:#{job_id}")
          header
        end
      end
    end
  end
end
