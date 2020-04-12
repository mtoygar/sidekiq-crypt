# frozen_string_literal: true

require 'test_helper'

class CipherTest < Sidekiq::Crypt::TestCase
  def setup
    super
    configure_sidekiq_crypt
  end

  def test_encrypts_given_string
    assert_equal("PdHia8epi6I8IUs+Ya9WIQ==\n", cipher.encrypt('A SECRET', valid_iv))
  end

  def test_decrypts_given_parameter
    assert_equal('A SECRET', cipher.decrypt('PdHia8epi6I8IUs+Ya9WIQ==', valid_iv, 'V1'))
  end

  private

  def cipher
    Sidekiq::Crypt::Cipher
  end

  def valid_iv
    # a valid iv should be at least 16 bytes
    '1' * 16
  end
end
