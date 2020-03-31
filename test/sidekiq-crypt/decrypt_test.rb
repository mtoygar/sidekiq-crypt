# frozen_string_literal: true

require "test_helper"

class DecryptTest < Sidekiq::Crypt::TestCase
  def setup
    Sidekiq.redis do |conn|
      conn.set("sidekiq-crpyt-header:#{job_id}", JSON.generate(nonce: Base64.encode64(valid_iv)))
    end
  end

  def test_reads_iv_from_redis
    assert_equal(valid_iv, decryptor.read_iv_from_redis(job_id))
  end

  def test_deletes_sidekiq_crypt_header_from_redis
    decryptor.read_iv_from_redis(job_id)

    Sidekiq.redis do |conn|
      assert_nil(conn.get("sidekiq-crpyt-header:#{job_id}"))
    end
  end

  def test_decrypts_given_parameter
    assert_equal('A SECRET', decryptor.call('PdHia8epi6I8IUs+Ya9WIQ==', valid_iv))
  end

  private

  def decryptor
    Sidekiq::Crypt::DefaultCipher::Decrypt
  end

  def job_id
    '5178fe171bdb2e925b3b2020'
  end

  def valid_iv
    # a valid iv should be at least 16 bytes
    '1' * 16
  end
end
