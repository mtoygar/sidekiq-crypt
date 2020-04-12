# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require File.expand_path('../../helpers/redis_helpers', __dir__)
require File.expand_path('../../helpers/sidekiq_helpers', __dir__)
require File.expand_path('../../helpers/utils', __dir__)

class SidekiqCrypt::EncryptedWorkerWithKeysTest < ActiveSupport::TestCase
  include RedisHelpers
  include SidekiqHelpers
  include Utils

  def setup
    Sidekiq.redis(&:flushdb)
    configure_sidekiq_crypt
  end

  def test_safe_worker_does_not_write_header_on_redis
    Sidekiq::Testing.disable! do
      job_id = SidekiqCrypt::EncryptedWorkerWithKeys.perform_async(password: '123456', divider: '0')

      assert_equal(%w[password divider], sidekiq_crypt_header(job_id)['encrypted_keys'])

      assert_raises('TypeError') do
        execute_job
      end

      assert_not_nil(sidekiq_crypt_header(job_id))
      assert_equal('123456', decrypt_retried_job_param(job_id: job_id, key: 'password'))
      assert_equal('0', decrypt_retried_job_param(job_id: job_id, key: 'divider'))
    end
  end

  def test_encrypted_worker_with_key_does_not_consider_rails_filter_params
    configure_sidekiq_crypt

    Sidekiq::Testing.disable! do
      job_id = SidekiqCrypt::EncryptedWorkerWithKeys.perform_async(
        secret_key: '123456', divider: '0'
      )

      assert_equal(['divider'], sidekiq_crypt_header(job_id)['encrypted_keys'])

      assert_raises('TypeError') do
        execute_job
      end

      assert_not_nil(sidekiq_crypt_header(job_id))
      assert_equal('123456', retried_job_args['secret_key'])
      assert_equal('0', decrypt_retried_job_param(job_id: job_id, key: 'divider'))
    end
  end
end
