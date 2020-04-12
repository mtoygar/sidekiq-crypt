# frozen_string_literal: true

module Sidekiq
  module Crypt
    class ServerMiddleware
      FILTERED = '[FILTERED]'

      def call(_worker_class, job, _queue, _redis_pool = {})
        return yield unless encrypted_worker?(job)

        encrypt_secret_params(job)

        yield

        delete_encryption_header(job['jid'])
      rescue StandardError => e
        if encrypted_worker?(job)
          Traverser.new(@encryption_header[:encrypted_keys]).traverse!(job['args'], filter_proc)
        end

        raise e
      end

      private

      def encrypt_secret_params(job)
        @encryption_header = read_encryption_header_from_redis(job['jid'])
        Traverser.new(@encryption_header[:encrypted_keys]).traverse!(job['args'], decryption_proc)
      end

      def encrypted_worker?(job)
        klass = worker_klass(job)
        klass && klass.ancestors.include?(Sidekiq::Crypt::Worker)
      end

      def worker_klass(job)
        klass = begin
                  job['args'][0]['job_class'] || job['class']
                rescue StandardError
                  job['class']
                end
        klass.is_a?(Class) ? klass : Module.const_get(klass)
      end

      def decryption_proc
        proc do |_key, param|
          Cipher.decrypt(param, @encryption_header[:iv], @encryption_header[:key_version])
        end
      end

      def filter_proc
        proc { |_key, _param| FILTERED }
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
          conn.get("sidekiq-crpyt-header:#{job_id}")
        end
      end

      def delete_encryption_header(job_id)
        Sidekiq.redis do |conn|
          conn.del("sidekiq-crpyt-header:#{job_id}")
        end
      end
    end
  end
end
