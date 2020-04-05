require File.expand_path('../../../test_helper', __FILE__)
require File.expand_path('../../../helpers/redis_helpers', __FILE__)
require File.expand_path('../../../helpers/sidekiq_helpers', __FILE__)
require File.expand_path('../../../helpers/utils', __FILE__)

class SidekiqCrypt::EncryptedWorkerTest < ActiveSupport::TestCase
  include RedisHelpers
  include SidekiqHelpers
  include Utils

  def setup
    Sidekiq.redis {|c| c.flushdb }
  end

  def test_encrypted_worker_does_not_write_header_on_redis
    configure_sidekiq_crypt([:divider])

    Sidekiq::Testing.disable! do
      job_id = SidekiqCrypt::EncryptedWorker.perform_async(password: '123456', divider: '0')

      assert_not_nil(sidekiq_crypt_header(job_id))

      assert_raises('TypeError') do
        execute_job
      end

      assert_not_nil(sidekiq_crypt_header(job_id))
      assert_equal('123456', decrypt_retried_job_param(job_id: job_id, key: 'password'))
      assert_equal('0', decrypt_retried_job_param(job_id: job_id, key: 'divider'))
    end
  end

  def test_encrypted_worker_considers_rails_filter_params_by_default
    configure_sidekiq_crypt

    Sidekiq::Testing.disable! do
      job_id = SidekiqCrypt::EncryptedWorker.perform_async(password: '123456', divider: '0')

      assert_equal(['password'], sidekiq_crypt_header(job_id)['encrypted_keys'])

      assert_raises('TypeError') do
        execute_job
      end

      assert_not_nil(sidekiq_crypt_header(job_id))
      assert_equal('123456', decrypt_retried_job_param(job_id: job_id, key: 'password'))
      assert_equal('0', retried_job_args['divider'])
    end
  end

  def test_encrypted_worker_excludes_rails_filter_params
    configure_sidekiq_crypt([:divider], exclude_rails_filters: true)

    Sidekiq::Testing.disable! do
      job_id = SidekiqCrypt::EncryptedWorker.perform_async(password: '123456', divider: '0')

      assert_equal(['divider'], sidekiq_crypt_header(job_id)['encrypted_keys'])

      assert_raises('TypeError') do
        execute_job
      end

      assert_not_nil(sidekiq_crypt_header(job_id))
      assert_equal('123456', retried_job_args['password'])
      assert_equal('0', decrypt_retried_job_param(job_id: job_id, key: 'divider'))
    end
  end
end
