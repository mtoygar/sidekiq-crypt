require "test_helper"

class Sidekiq::CryptTest < Sidekiq::Crypt::TestCase
  def test_that_it_has_a_version_number
    assert_equal('0.1.0', ::Sidekiq::Crypt::VERSION)
  end

  def test_adds_filters_using_configure
    configure_sidekiq_crypt(filters: ['key', /^secret.*/])

    assert_equal(['key', /^secret.*/], Sidekiq::Crypt.configuration.filters)
  end

  def test_raises_error_if_no_filter_specified
    assert_raised_error('you must specify at least one filter') do
      configure_sidekiq_crypt(filters: [])
    end
  end

  def test_raises_error_if_no_filter_specified
    assert_raised_error('you must specify current key version') do
      configure_sidekiq_crypt(options: {})
    end
  end

  def test_raises_error_if_no_key_store_specified
    assert_raised_error('you must specify a hash for key store') do
      configure_sidekiq_crypt(options: { current_key_version: 'V3' })
    end
  end

  def test_raises_error_if_empty_key_store_specified
    assert_raised_error('you must specify a hash for key store') do
      configure_sidekiq_crypt(options: { current_key_version: 'V3', key_store: {} })
    end
  end

  def test_raises_error_if_key_store_and_current_version_does_not_match
    assert_raised_error("current_key_version can't be found in key_store") do
      configure_sidekiq_crypt(options: { current_key_version: 'V2', key_store: { 'V1' => 123 } })
    end
  end

  def test_skips_rails_filter_params_on_demand
    skip 'TODO add tests for skipping rails filter parameters, maybe add a fixture app'
  end

  def test_inject_sidekiq_middleware
    skip 'TODO add tests to test middleware injection'
  end

  private

  def assert_raised_error(error_message)
    error = assert_raises do
      yield
    end

    assert_equal(error_message, error.message)
  end
end
