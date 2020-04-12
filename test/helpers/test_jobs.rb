# frozen_string_literal: true

class SafeWorker; end

class SecretWorker
  include Sidekiq::Crypt::Worker
end

class SecretWorkerWithKey
  include Sidekiq::Crypt::Worker

  encrypted_keys :some_key
end
