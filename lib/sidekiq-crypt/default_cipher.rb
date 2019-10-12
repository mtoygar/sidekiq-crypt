require 'openssl'
require 'base64'

module Sidekiq
  module Crypt
    module DefaultCipher
      CIPHER_KEY = ENV['CIPHER_KEY']

      class Encrypt
        attr_reader :cipher

        def self.random_iv
          OpenSSL::Cipher::AES.new(256, :CBC).encrypt.random_iv
        end

        def self.write_encryption_header_to_redis(job_id, iv)
          Sidekiq.redis_pool.with do |conn|
            conn.sadd("sidekiq-crpyt-header:#{job_id}", JSON.generate(nonce: Base64.encode64(iv)))
          end
        end

        def self.call(confidential_param, iv)
          encryptor = new(iv)
          # use base64 to prevent Encoding::UndefinedConversionError
          Base64.encode64(encryptor.cipher.update(confidential_param.to_s) + encryptor.cipher.final)
        end

        def initialize(iv)
          @iv = iv
          @cipher = OpenSSL::Cipher::AES.new(256, :CBC).encrypt

          cipher.key = Sidekiq::Crypt::DefaultCipher::CIPHER_KEY
          cipher.iv = iv
        end
      end

      class Decrypt; end
    end
  end
end
