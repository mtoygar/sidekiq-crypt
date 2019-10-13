# frozen_string_literal: true

require "test_helper"
require "sidekiq/testing"

class DummyWorker; end

class ServerMiddlewareTest < Sidekiq::Crypt::TestCase
  def setup
    Sidekiq.redis do |conn|
      conn.sadd("sidekiq-crpyt-header:#{job_id}", JSON.generate(nonce: Base64.encode64(valid_iv)))
    end
  end

  def test_decrypts_filtered_job_params
    # shallow copy params from job_params to assert later
    params = job_params
    server_middleware.call(DummyWorker, params, 'default', nil) {}

    assert_equal('1234123412341234', params['args'][1]['secret_key1'])
    assert_equal('A SECRET', params['args'][1]['secret_key2'])
  end

  private

  def server_middleware
    Sidekiq::Crypt::ServerMiddleware.new(configuration: config)
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

  def config
    config = Sidekiq::Crypt::Configuration.new
    config.filters << [/^secret.*/]
    config.filters.flatten!

    config
  end
end
