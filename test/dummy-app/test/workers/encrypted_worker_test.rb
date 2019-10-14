require File.expand_path('../../test_helper', __FILE__)

class EncryptedWorkerTest < ActiveSupport::TestCase
  def test_that_kitty_can_eat
    assert_equal(12, EncryptedWorker.dummy)
  end
end
