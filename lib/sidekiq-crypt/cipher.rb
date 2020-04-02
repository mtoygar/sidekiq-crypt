require 'openssl'
require 'base64'

module Sidekiq
  module Crypt
    module Cipher
      class << self
        def encrypt(confidential_param, iv)
          encryptor = encryption_cipher(iv)
          # use base64 to prevent Encoding::UndefinedConversionError
          Base64.encode64(encryptor.update(confidential_param.to_s) + encryptor.final)
        end

        def decrypt(confidential_param, iv, key_version)
          decryptor_cipher = decryption_cipher(iv, key_version)

          decryptor_cipher.update(Base64.decode64(confidential_param.to_s)) + decryptor_cipher.final
        end

        def random_iv
          OpenSSL::Cipher::AES.new(256, :CBC).encrypt.random_iv
        end

        private

        def encryption_cipher(iv)
          cipher = OpenSSL::Cipher::AES.new(256, :CBC).encrypt
          cipher.key = Sidekiq::Crypt.configuration.current_key
          cipher.iv = iv

          cipher
        end

        def decryption_cipher(iv, key_version)
          cipher = OpenSSL::Cipher::AES.new(256, :CBC).decrypt
          cipher.key = Sidekiq::Crypt.configuration.key_by_version(key_version)
          cipher.iv = iv

          cipher
        end
      end
    end
  end
end
