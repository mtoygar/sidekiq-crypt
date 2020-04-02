# frozen_string_literal: true

module Sidekiq
  module Crypt
    module Worker
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :sidekiq_crypt_worker_filters

        def encrypted_keys(*filter_keys)
          @sidekiq_crypt_worker_filters = filter_keys
        end
      end
    end
  end
end
