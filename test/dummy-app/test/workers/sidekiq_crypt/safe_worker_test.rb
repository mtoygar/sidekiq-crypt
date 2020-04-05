require File.expand_path('../../../test_helper', __FILE__)
require File.expand_path('../../../helpers/redis_helpers', __FILE__)
require File.expand_path('../../../helpers/utils', __FILE__)

class SidekiqCrypt::SafeWorkerTest < ActiveSupport::TestCase
  include RedisHelpers
  include SidekiqHelpers
  include Utils

  def setup
    Sidekiq.redis {|c| c.flushdb }
    configure_sidekiq_crypt
  end

  def test_safe_worker_does_not_write_header_on_redis
    job_id = SidekiqCrypt::SafeWorker.perform_async(password: '123456', divider: 0)

    assert_nil(sidekiq_crypt_header(job_id))

    assert_raises('ZeroDivisionError') do
      SidekiqCrypt::SafeWorker.drain
    end
  end

  def test_safe_worker_retries
    Sidekiq::Testing.disable! do
      SidekiqCrypt::SafeWorker.perform_async(password: '123456', divider: 0)

      assert_raises('ZeroDivisionError') do
        execute_job
      end

      assert_equal('123456', retried_job_args['password'])
      assert_equal(0, retried_job_args['divider'])
    end
  end
end
