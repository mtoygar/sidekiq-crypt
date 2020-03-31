# frozen_string_literal: true

require "test_helper"
require "sidekiq/testing"

class ClientMiddlewareTest < Sidekiq::Crypt::TestCase
  class DummyWorker; end

  def test_writes_encryption_header_to_redis
    stub_iv_creation do
      client_middleware.call(DummyWorker, job_params, 'default', nil) {}

      nonce_payload = redis.get("sidekiq-crpyt-header:5178fe171bdb2e925b3b2020")
      assert_equal({ 'nonce' => Base64.encode64(valid_iv) }, JSON.parse(nonce_payload))
    end
  end

  def test_encrypts_filtered_params
    stub_iv_creation do
      # shallow copy params from job_params to assert later
      params = job_params
      client_middleware.call(DummyWorker, params, 'default', nil) {}

      assert_equal(encrypted_value('1234123412341234'), params['args'][1]['secret_key1'])
      assert_equal(encrypted_value('A SECRET'), params['args'][1]['secret_key2'])
    end
  end

  private

  def client_middleware
    Sidekiq::Crypt::ClientMiddleware.new(configuration: config)
  end

  def redis
    Sidekiq.redis { |conn| conn }
  end

  def stub_iv_creation
    OpenSSL::Random.stub(:random_bytes, valid_iv) do
      yield
    end
  end

  def valid_iv
    # a valid iv should be at least 16 bytes
    '1' * 16
  end

  def job_params
    {
      "class" => "DummyWorker",
      "args" =>[3, {
              "secret_key1" =>"1234123412341234",
              "secret_key2" =>"A SECRET",
              "some_key" =>"123"
            }
        ],
      "retry" =>false,
      "queue" =>"default",
      "jid" =>"5178fe171bdb2e925b3b2020",
      "created_at" =>1570907859.9315178
    }
  end

  def config
    config = Sidekiq::Crypt::Configuration.new
    config.filters << [/^secret.*/]
    config.filters.flatten!

    config
  end

  def encrypted_value(value)
    cipher = OpenSSL::Cipher::AES.new(256, :CBC).encrypt
    cipher.key = Sidekiq::Crypt::DefaultCipher::CIPHER_KEY
    cipher.iv = valid_iv

    Base64.encode64(cipher.update(value.to_s) + cipher.final)
  end
end
