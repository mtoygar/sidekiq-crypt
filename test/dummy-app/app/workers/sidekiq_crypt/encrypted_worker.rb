# frozen_string_literal: true

module SidekiqCrypt
  class EncryptedWorker
    include Sidekiq::Worker
    include Sidekiq::Crypt::Worker

    def perform(params)
      1 / params['divider']
    end
  end
end
