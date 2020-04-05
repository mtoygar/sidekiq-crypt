module RedisHelpers
  def sidekiq_crypt_header(job_id)
    header = Sidekiq.redis { |conn| conn.get("sidekiq-crpyt-header:#{job_id}") }
    header && JSON.parse(header)
  end

  def decrypt_retried_job_param(job_id:, key:)
    header = sidekiq_crypt_header(job_id)

    Sidekiq::Crypt::Cipher.decrypt(
      retried_job_args[key],
      Base64.decode64(header['nonce']),
      header['key_version']
    )
  end

  def retried_job_args
    Sidekiq::RetrySet.new.first.args[0]
  end
end
