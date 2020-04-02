# frozen_string_literal: true

require "test_helper"
require "sidekiq/testing"

class ClientMiddlewareTest < Sidekiq::Crypt::TestCase
  def setup
    super
    configure_sidekiq_crypt
  end

  def test_writes_nonce_to_encryption_header_on_redis
    stub_iv_creation do
      client_middleware.call(EncryptedWorker, job_params, 'default', nil) {}

      assert_equal(Base64.encode64(valid_iv), JSON.parse(nonce_payload)['nonce'])
    end
  end

  def test_writes_encrypted_keys_to_encryption_header_on_redis
    stub_iv_creation do
      client_middleware.call(EncryptedWorker, job_params, 'default', nil) {}

      assert_equal(['secret_key1', 'secret_key2'], JSON.parse(nonce_payload)['encrypted_keys'])
    end
  end

  def test_writes_encryption_key_version_to_encryption_header_on_redis
    stub_iv_creation do
      client_middleware.call(EncryptedWorker, job_params, 'default', nil) {}

      assert_equal('V1', JSON.parse(nonce_payload)['key_version'])
    end
  end

  def test_encrypts_filtered_params
    stub_iv_creation do
      # shallow copy params from job_params to assert later
      params = job_params
      client_middleware.call(EncryptedWorker, params, 'default', nil) {}

      assert_equal(encrypted_value('1234123412341234'), params['args'][1]['secret_key1'])
      assert_equal(encrypted_value('A SECRET'), params['args'][1]['secret_key2'])
      assert_equal('123', params['args'][1]['some_key'])
    end
  end

  def test_encrypts_params_with_stated_keys
    stub_iv_creation do
      # shallow copy params from job_params to assert later
      params = job_params('EncryptedWorkerWithKey')
      client_middleware.call(EncryptedWorkerWithKey, params, 'default', nil) {}

      assert_equal('1234123412341234', params['args'][1]['secret_key1'])
      assert_equal('A SECRET', params['args'][1]['secret_key2'])
      assert_equal(encrypted_value('123'), params['args'][1]['some_key'])
    end
  end

  def test_does_not_encrypt_filtered_params_if_sidekiq_crypt_worker_is_not_included
    # shallow copy params from job_params to assert later
    params = job_params('UnencryptedWorker')
    client_middleware.call(UnencryptedWorker, params, 'default', nil) {}

    assert_equal('1234123412341234', params['args'][1]['secret_key1'])
    assert_equal('A SECRET', params['args'][1]['secret_key2'])
    assert_equal('123', params['args'][1]['some_key'])
  end

  def test_does_not_write_encryption_header_on_redis_if_sidekiq_crypt_worker_is_not_included
    client_middleware.call(UnencryptedWorker, job_params('UnencryptedWorker'), 'default', nil) {}

    assert_nil(nonce_payload)
  end

  private

  def client_middleware
    Sidekiq::Crypt::ClientMiddleware.new(configuration: config)
  end

  def nonce_payload
    Sidekiq.redis { |conn| conn.get("sidekiq-crpyt-header:5178fe171bdb2e925b3b2020") }
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

  def job_params(worker_name = 'EncryptedWorker')
    {
      "class" => worker_name,
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
    config = Sidekiq::Crypt::Configuration.new(config_key_attrs)
    config.filters << [/^secret.*/]
    config.filters.flatten!

    config
  end

  def encrypted_value(value)
    cipher = OpenSSL::Cipher::AES.new(256, :CBC).encrypt
    cipher.key = ENV['CIPHER_KEY']
    cipher.iv = valid_iv

    Base64.encode64(cipher.update(value.to_s) + cipher.final)
  end
end
