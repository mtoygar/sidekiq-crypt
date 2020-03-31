# frozen_string_literal: true

require "test_helper"
require "sidekiq/testing"

class ServerMiddlewareTest < Sidekiq::Crypt::TestCase
  class DummyWorker; end

  def setup
    Sidekiq.redis do |conn|
      conn.set("sidekiq-crpyt-header:#{job_id}", JSON.generate(
        nonce: Base64.encode64(valid_iv),
        encrypted_keys: [:secret_key1, 'secret_key2']
      ))
    end
    sleep 0.2
  end

  def test_decrypts_filtered_job_params
    params = job_params # shallow copy params from job_params to assert later
    server_middleware.call(DummyWorker, params, 'default', nil) {}

    assert_equal('1234123412341234', params['args'][1]['secret_key1'])
    assert_equal('A SECRET', params['args'][1]['secret_key2'])
  end

  def test_filters_job_params_on_job_failure
    params = job_params # shallow copy params from job_params to assert later

    error = StandardError.new
    middleware_error = assert_raises do
      server_middleware.call(DummyWorker, params, 'default', nil) { raise error }
    end

    assert_equal('[FILTERED]', params['args'][1]['secret_key1'])
    assert_equal('[FILTERED]', params['args'][1]['secret_key2'])
    assert_equal('123', params['args'][1]['some_key'])
    assert_equal(middleware_error, error)
  end

  private

  def server_middleware
    Sidekiq::Crypt::ServerMiddleware.new
  end

  def valid_iv
    # a valid iv should be at least 16 bytes
    '1' * 16
  end

  def job_params
    {
      "class" => "DummyWorker",
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
