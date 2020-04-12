# Sidekiq::Crypt

sidekiq-crypt enables you to encryt your secret keys on redis. It is an alternative to [sidekiq's enterprise encryption](https://github.com/mperham/sidekiq/wiki/Ent-Encryption) feature. If you or your project has enough resources, you should prefer that option.

After sidekiq-crypt parameters of your secret worker would look like below.

> 79, {"credit_card_number"=>"agBCqI8vlvn4mx0L8vkbrJr1nstV459w4d6hVNqZC1A=\n", "name_on_credit_card"=>"h6fdq3kbXNXhfx/iKIy5fA==\n", "cvc"=>"wEAB4pCISRUvWVXtDPaOKA==\n", "expiration"=>"cgOI/Ks7BfldTlB+6F23LQ==\n", "installments"=>1}

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-crypt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-crypt

## Compatibility

Tested with

- Ruby 2.2.10+

- Rails 4.2+

- Sidekiq 5.2.7

## Usage

You should add below block in an initializer. Since you can bump your encryption keys, the current key version is required. The key store hash enables sidekiq crypt to access encryption keys by version.

```ruby
Sidekiq::Crypt.configure(current_key_version: current_key_version, key_store: key_store)
```

Alternatively you can use below.
```ruby
Sidekiq::Crypt.configure do |config|
  config.current_key_version = options[:current_key_version]
  config.key_store = options[:key_store]
end
```

For example, if you set current_key_version as `'V2'` and key_store as `{ V1: 'a_key', V2: 'yet_another_key' }`, sidekiq-crypt will use `'yet_another_key'` to encrypted new jobs. However, if you have jobs encrypted with `V1` key version in redis sidekiq-crypt will decrypt them by using `'a_key'`. When you make sure that you no longer have any job encryted with first key version, you can safely remove `V1: 'a_key'` from the key_store hash.

Additionally, to use sidekiq crypt in a worker you must include `Sidekiq::Crypt::Worker` module to your worker class.

```ruby
class SecretWorker
  include Sidekiq::Worker
  include Sidekiq::Crypt::Worker
  ...
```

sidekiq-crypt automatically traverse all parameters sent to sidekiq to find a hash key that are configured to be encrypted. There are 2 ways to configure encrpyted hash.

#### 1. Explicit way (Recommended)
```ruby
class SecretWorker
  include Sidekiq::Worker
  include Sidekiq::Crypt::Worker

  # explicitly state which keys are gonna be encrypted
  encrypted_keys :credit_card_number, :cvc, /^secret.*/
```
As stated, sidekiq-crypt automatically traverse all parameters. For example in below case it will find and encrypt `credit_card_number`, `cvc` and `secret_key`.
`SecretWorker.perform_async([1, credit_card_number: '1234567812345678'], { cvc: 123, secret_key: 'CONFIDENTIAL' })`

Note: This method overrides filters stated on initialization. (see below)

#### 2. State filters in initialization

```ruby
Sidekiq::Crypt.configure do |config|
  config.current_key_version = options[:current_key_version]
  config.key_store = options[:key_store]
  config.filters << [:credit_card_number, :cvc, /^secret.*/]
end
```

By default Sidekiq::Crypt initialize config.filters with `Rails.application.config.filter_parameters`. You can add additional filters to it by stating a filter array like above.


With the above config `credit_card_number`, `password` and `secret_key` will be encrypted, assuming `password` is included in rails filter params.
`credit_card_number`, `cvc` and `secret_key`.
`SecretWorker.perform_async([1, credit_card_number: '1234567812345678'], { password: 123, secret_key: 'CONFIDENTIAL' })`

To disable rails filter params inclusion, you must call configure method with `exclude_rails_filters` parameter.

```ruby
Sidekiq::Crypt.configure(exclude_rails_filters: true)
```

## Notes

- sidekiq-crypt is a [sidekiq middleware](https://github.com/mperham/sidekiq/wiki/Middleware). You should be careful about middleware ordering. Start sidekiq in verbose mode to see where sidekiq-crypt is in the middleware chain.

```ruby
bundle exec sidekiq -v
```

- sidekiq-cypyt uses OpenSSL's aes-256-cbc Cipher encryption.

## Caveats

Right now, only string attributes are accepted. If you try to encrypted an integer string version will be return to the worker. For example if you send `secret_key: 0` to your worker, sidekiq-crypt will encrypt it on redis, but return `secret_key: '0'` to the worker.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mtoygar/sidekiq-crypt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sidekiq::Crypt project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mtoygar/sidekiq-crypt/blob/master/CODE_OF_CONDUCT.md).

