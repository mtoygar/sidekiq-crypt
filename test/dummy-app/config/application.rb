# frozen_string_literal: true

require File.expand_path('boot', __dir__)

require 'rails/railtie' # Only for Rails >= 4.2
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default)

module DummyRailties
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
