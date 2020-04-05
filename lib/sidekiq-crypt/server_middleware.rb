# frozen_string_literal: true

module Sidekiq
  module Crypt
    class ServerMiddleware
      FILTERED = '[FILTERED]'.freeze

      def call(worker_class, job, queue, redis_pool = {})
        unless encrypted_worker?(job)
          return yield
        end

        @encryption_header = read_encryption_header_from_redis(job['jid'])
        Traverser.new(@encryption_header[:encrypted_keys]).traverse!(job['args'], decryption_proc)

        yield

        delete_encryption_header(job['jid'])
      rescue => error
        if encrypted_worker?(job)
          Traverser.new(@encryption_header[:encrypted_keys]).traverse!(job['args'], filter_proc)
        end

        raise error
      end

      private

      def encrypted_worker?(job)
        klass = worker_klass(job)
        klass && klass.ancestors.include?(Sidekiq::Crypt::Worker)
      end

      def worker_klass(job)
        klass = job['args'][0]['job_class'] || job['class'] rescue job['class']
        klass.is_a?(Class) ? klass : Module.const_get(klass)
      end

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
