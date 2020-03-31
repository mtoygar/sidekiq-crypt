require 'openssl'
require 'base64'

module Sidekiq
  module Crypt
    module DefaultCipher
      CIPHER_KEY = ENV['CIPHER_KEY']

      class Encrypt
        class << self
          def random_iv
            OpenSSL::Cipher::AES.new(256, :CBC).encrypt.random_iv
          end

          def write_encryption_header_to_redis(job_id, iv)
            Sidekiq.redis_pool.with do |conn|
              conn.set("sidekiq-crpyt-header:#{job_id}", JSON.generate(nonce: Base64.encode64(iv)))
            end
          end

          def call(confidential_param, iv)
            encryptor = cipher(iv)
            # use base64 to prevent Encoding::UndefinedConversionError
            Base64.encode64(encryptor.update(confidential_param.to_s) + encryptor.final)
          end

          private

          def cipher(iv)
            cipher = OpenSSL::Cipher::AES.new(256, :CBC).encrypt
            cipher.key = Sidekiq::Crypt::DefaultCipher::CIPHER_KEY
            cipher.iv = iv

            cipher
          end
        end
      end

      class Decrypt
        class << self
          def read_iv_from_redis(job_id)
            header = read_encryption_header(job_id)

            Base64.decode64(JSON.parse(header)['nonce'])
          end

          def call(confidential_param, iv)
            decryptor_cipher = cipher(iv)

            decryptor_cipher.update(Base64.decode64(confidential_param.to_s)) + decryptor_cipher.final
          end

          private

          def read_encryption_header(job_id)
            Sidekiq.redis_pool.with do |conn|
              header = conn.get("sidekiq-crpyt-header:#{job_id}")
              conn.del("sidekiq-crpyt-header:#{job_id}")
              header
            end
          end

          def cipher(iv)
            cipher = OpenSSL::Cipher::AES.new(256, :CBC).decrypt
            cipher.key = Sidekiq::Crypt::DefaultCipher::CIPHER_KEY
            cipher.iv = iv

            cipher
          end
        end
      end
    end
  end
end
