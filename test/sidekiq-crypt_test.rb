require "test_helper"

class Sidekiq::CryptTest < Sidekiq::Crypt::TestCase
  def setup
    # resets filters in configuration(it is memoized)
    Sidekiq::Crypt.configuration.filters.map!{|_filter| []}.flatten!
  end

  def test_that_it_has_a_version_number
    assert_equal('0.1.0', ::Sidekiq::Crypt::VERSION)
  end

  def test_adds_filters_using_configure
    Sidekiq::Crypt.configure { |config| config.filters << ['key', /^secret.*/] }

    assert_equal(['key', /^secret.*/], Sidekiq::Crypt.configuration.filters)
  end

  def test_raises_error_if_no_filter_specified
    error = assert_raises do
      Sidekiq::Crypt.configure
    end

    assert_equal('you must specify at least one filter', error.message)
  end

  def test_skips_rails_filter_params_on_demand
    skip 'TODO add tests for skipping rails filter parameters, maybe add a fixture app'
  end

  def test_inject_sidekiq_middleware
    skip 'TODO add tests to test middleware injection'
  end
end
