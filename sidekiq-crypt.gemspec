require File.expand_path('../lib/sidekiq-crypt/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'sidekiq-crypt'
  spec.version     = Sidekiq::Crypt::VERSION
  spec.date        = '2019-10-06'
  spec.summary     = 'encrypts confidential sidekiq parameters on redis'
  spec.description = 'A gem to manage confidential job parameters'
  spec.authors     = ['Murat Toygar']
  spec.email       = ['toygar-murat@hotmail.com']
  spec.files       = ['lib/sidekiq-crypt.rb']
  spec.homepage    = 'https://rubygems.org/gems/sidekiq-crypt'
  spec.license     = 'MIT'

  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq', '>= 3.0'
  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'appraisal'
end
