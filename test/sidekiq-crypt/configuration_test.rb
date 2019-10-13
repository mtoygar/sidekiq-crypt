# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Sidekiq::Crypt::TestCase
  def test_sets_crypto_classes
    config = Sidekiq::Crypt::Configuration.new

    assert_equal(Sidekiq::Crypt::DefaultCipher::Encrypt, config.encryption_class)
    assert_equal(Sidekiq::Crypt::DefaultCipher::Decrypt, config.decryption_class)
  end

  def test_sets_rails_filters
    skip 'TODO add tests for rails filters, maybe add a fixture app'
  end
end
