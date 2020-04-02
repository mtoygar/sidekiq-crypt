# frozen_string_literal: true

require 'sidekiq-crypt/traverser'
require 'set'

module Sidekiq
  module Crypt
    class ClientMiddleware
      def initialize(opts = {})
        @configuration = opts[:configuration]
        @encrypted_keys = Set.new
      end

      def call(worker_class, job, queue, redis_pool)
        if encrypted_worker?(worker_class, job)
          @iv = Cipher.random_iv
          traverser.traverse!(job['args'], encryption_proc)
          write_encryption_header_to_redis(job['jid'], encrypted_keys, @iv)
        end

        yield
      end

      private

      attr_reader :configuration, :encrypted_keys

      def encrypted_worker?(worker_class, job)
        @worker_klass = worker_class(worker_class, job)
        @worker_klass && @worker_klass.ancestors.include?(Sidekiq::Crypt::Worker)
      end

      def traverser
        Traverser.new(@worker_klass.sidekiq_crypt_worker_filters || configuration.filters)
      end

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
          encrypted_keys << key
          Cipher.encrypt(param, @iv)
        end
      end

      def worker_class(worker_class, job)
        klass = job['args'][0]['job_class'] || worker_class rescue worker_class

        if klass.is_a?(Class)
          klass
        elsif Module.const_defined?(klass)
          Module.const_get(klass)
        else
          nil
        end
      end
    end
  end
end
