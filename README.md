# ForgetThat

ForgetThat is a tool replace critical old user data in your rails application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'forget_that'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install forget_that

## Configuration

Before gem could be used, a config in `config/anonymization_config.yml` in must be created:

```YAML
config:
  retention_time:
    value: 90
    unit: 'days'

schema:
  table1:
    name: 'Peter'
  table2:
    phone: '%{random_phone}'
```

Pay attention that default placeholders are `random_date`, `hex_string`, `random_phone`, `fake_personal_id_number`, `random_amount`. You can add your own placeholders by supplying them to initializer (see below)

## Database migration

After you created a config you can generate migration that adds anonymization metadata to corresponding tables:

  $ rails g forget_that:install

Do not forget to run the migration:

  $ rails db:migrate

## Usage

In order to run the service, you can create an instance and use the `call` method:

```ruby
ForgetThat::Service.new.call
```

Calling that will find records older then `retention_time` in your configured tables and replace the configured fields with configured values.
If some of the placeholders are not supplied, or some tables do not contain `anonymization` flag the error will be raised.

### Sidekiq

Typical use for the service might be a scheduled Sidekiq worker:

```ruby
class AnonymizeCustomerData
  include Sidekiq::Worker

  sidekiq_options retry: 10

  def perform
    Rails.logger.info('[AnonymizeCustomerData.perform] start')

    ForgetThat::Service.new.call

    Rails.logger.info('[AnonymizeCustomerData.perform] done')
  end
end
```

### Custom placeholders

The default placeholders are `random_date`, `hex_string`, `random_phone`, `fake_personal_id_number`, `random_amount`. In some cases this might not be enough or behaviour might not be desireable. In that case you can supply `anonymizers` hash.

```ruby
ForgetThat::Service.new(
  anonymizers: {
    foobar: -> { 'foo' + 'bar' }
  }
).call
```

Each member of this hash must be a zero-arity lambda that returns a string value.

After anonymizer was supplied with the lambda, it can be used in the config.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vehiculum-berlin/forget_that.
