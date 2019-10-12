$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "sidekiq-crypt"
require 'sidekiq-crypt/traverser'

require "minitest/autorun"
