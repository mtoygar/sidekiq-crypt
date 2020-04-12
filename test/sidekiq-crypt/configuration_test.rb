# frozen_string_literal: true

require 'test_helper'

class ConfigurationTest < Sidekiq::Crypt::TestCase
  def test_sets_current_key_version
    config = Sidekiq::Crypt::Configuration.new(dummy_key_attributes)

    assert_equal('ThisPasswordIsReallyHardToGuess!', config.current_key)
  end

  def test_returns_secret_key_for_given_versioon
    config = Sidekiq::Crypt::Configuration.new(dummy_key_attributes)

    assert_equal('old_key', config.key_by_version('V1'))
  end

  def test_stringfy_key_store_keys
    config = Sidekiq::Crypt::Configuration.new(dummy_key_attributes)

    assert_equal(Base64.strict_encode64('old_key'), config.key_store['V1'])
    assert_equal(Base64.strict_encode64('ThisPasswordIsReallyHardToGuess!'), config.key_store['V2'])
  end

  private

  def dummy_key_attributes
    {
      current_key_version: 'V2',
      key_store: { V1: Base64.strict_encode64('old_key'), V2: ENV['CIPHER_KEY'] }
    }
  end
end
