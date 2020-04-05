# frozen_string_literal: true

require "test_helper"
require "sidekiq/testing"

class ServerMiddlewareTest < Sidekiq::Crypt::TestCase
  def test_decrypts_filtered_job_params
    params = job_params # shallow copy params from job_params to assert later
    call_middleware(params) {}

    assert_equal('1234123412341234', params['args'][1]['secret_key1'])
    assert_equal('A SECRET', params['args'][1]['secret_key2'])
  end

  def test_filters_job_params_on_job_failure
    params = job_params # shallow copy params from job_params to assert later

    error = StandardError.new
    middleware_error = assert_raises do
      call_middleware(params) { raise error }
    end

    assert_equal('[FILTERED]', params['args'][1]['secret_key1'])
    assert_equal('[FILTERED]', params['args'][1]['secret_key2'])
    assert_equal('123', params['args'][1]['some_key'])
    assert_equal(middleware_error, error)
  end

  def test_decrypts_filtered_params_using_expired_key
    params = job_params # shallow copy params from job_params to assert later
    key_attrs = {
      current_key_version: 'V2', key_store: { 'V1' => ENV['CIPHER_KEY'], 'V2' => valid_key }
    }

    call_middleware(params, config_attrs: key_attrs) {}

    assert_equal('1234123412341234', params['args'][1]['secret_key1'])
    assert_equal('A SECRET', params['args'][1]['secret_key2'])
  end

  def test_deletes_sidekiq_crypt_header_from_redis
    call_middleware(job_params) {}

    Sidekiq.redis do |conn|
      assert_nil(conn.get("sidekiq-crpyt-header:#{job_id}"))
    end
  end

  def test_does_not_delete_sidekiq_crypt_header_from_redis_on_job_failure
    assert_raises do
      call_middleware(job_params) { raise error }
    end

    Sidekiq.redis do |conn|
      refute_nil(conn.get("sidekiq-crpyt-header:#{job_id}"))
    end
  end

  def test_does_not_decrypt_when_sidekiq_crypt_worker_not_included
    params = job_params('SafeWorker') # shallow copy params from job_params to assert later
    server_middleware.call(SafeWorker, params, 'default', nil) {}

    assert_equal('zrZcSf2pQZR5P1yBvYa9GdSmW0N+TMT1z6JzrPrgxWg=', params['args'][1]['secret_key1'])
    assert_equal('PdHia8epi6I8IUs+Ya9WIQ==', params['args'][1]['secret_key2'])
    assert_equal('123', params['args'][1]['some_key'])
  end

  private

  def call_middleware(params, config_attrs: config_key_attrs, &block)
    configure_sidekiq_crypt(options: config_attrs)
    Sidekiq.redis do |conn|
      conn.set("sidekiq-crpyt-header:#{job_id}", JSON.generate(
        nonce: Base64.encode64(valid_iv),
        encrypted_keys: [:secret_key1, 'secret_key2'],
        key_version: 'V1'
      ))
    end
    sleep 0.2

    server_middleware.call(SecretWorker, params, 'default', nil, &block)
  end

  def server_middleware
    Sidekiq::Crypt::ServerMiddleware.new
  end

  def valid_iv
    # a valid iv should be at least 16 bytes
    '1' * 16
  end

  def valid_key
    '1' * 32
  end

  def job_params(worker_name = 'SecretWorker')
    {
      "class" => worker_name,
      "args" =>[3, {
              "secret_key1" =>"zrZcSf2pQZR5P1yBvYa9GdSmW0N+TMT1z6JzrPrgxWg=",
              "secret_key2" =>"PdHia8epi6I8IUs+Ya9WIQ==",
              "some_key" =>"123"
            }
        ],
      "retry" =>false,
      "queue" =>"default",
      "jid" =>job_id,
      "created_at" =>1570907859.9315178
    }
  end

  def job_id
    '5178fe171bdb2e925b3b2020'
  end
end
