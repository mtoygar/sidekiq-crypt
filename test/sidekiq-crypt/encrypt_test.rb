# frozen_string_literal: true

require "test_helper"

class EncryptTest < Sidekiq::Crypt::TestCase
  def test_returns_random_iv
    stub_iv_creation do
      assert_equal(valid_iv, encryptor.random_iv)
    end
  end

  def test_writes_encryption_header_to_redis
    encryptor.write_encryption_header_to_redis('123', valid_iv)

    nonce_payload = redis.smembers("sidekiq-crpyt-header:123")
    assert_equal(1, nonce_payload.length)
    assert_equal({ 'nonce' => Base64.encode64(valid_iv) }, JSON.parse(nonce_payload[0]))
  end

  def test_encrypts_given_string
    assert_equal("PdHia8epi6I8IUs+Ya9WIQ==\n", encryptor.call('A SECRET', valid_iv))
  end

  private

  def encryptor
    Sidekiq::Crypt::DefaultCipher::Encrypt
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
end
