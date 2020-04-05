module SidekiqCrypt
  class EncryptedWorkerWithKeys
    include Sidekiq::Worker
    include Sidekiq::Crypt::Worker

    encrypted_keys :password, :divider

    def perform(params)
      1 / params['divider']
    end
  end
end
