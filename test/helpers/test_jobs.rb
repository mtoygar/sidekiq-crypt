class UnencryptedWorker; end

class EncryptedWorker
  include Sidekiq::Crypt::Worker
end

class EncryptedWorkerWithKey
  include Sidekiq::Crypt::Worker

  encrypted_keys :some_key
end
