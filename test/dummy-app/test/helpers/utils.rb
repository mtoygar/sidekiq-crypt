module Utils
  def configure_sidekiq_crypt(filters = [], exclude_rails_filters: false)
    Rails.application.config.filter_parameters = [:password, :secret_key]
    config = Sidekiq::Crypt.configuration
    config.filters = []
    config.send(:include_rails_filter_parameters, exclude_rails_filters)

    Sidekiq::Crypt.configure(exclude_rails_filters: exclude_rails_filters) do |config|
      config.current_key_version = 'V1'
      config.key_store = { 'V1' => ENV['CIPHER_KEY'] }
      config.filters << filters
    end
  end
end
