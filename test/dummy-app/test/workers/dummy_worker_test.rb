require File.expand_path('../../test_helper', __FILE__)

class DummyWorkerTest < ActiveSupport::TestCase
  def test_that_kitty_can_eat
    assert_equal(12, DummyWorker.dummy)
  end
end
