# ForgetThat

[![VEHICULUM](https://img.shields.io/circleci/build/github/vehiculum-berlin/forget_that/master?style=for-the-badge)](https://circleci.com/gh/vehiculum-berlin/forget_that)

ForgetThat is a tool to take care of critical data in your database. It replaces the critical pieces of data with anonymized data, according to pre-set per-application policy.

## Important notice

When misconfigured and/or misused this gem can effectively wipe important data from the database. Be responsible and test before running on production data.

## Prerequisites

- Ruby ~> 2.6.0
- ActiveRecord ~> 5
- Running Postgresql installation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'forget_that'
```

And then execute:

    $ bundle

## Configuration

Before gem could be used, a config in `config/anonymization_config.yml` in must be created:

```YAML
config: # config part is only valid for the `call` method which will write in db
  retention_time: # defines the newest record to be anonymized when `call` is used
    value: 90
    unit: 'days'

schema:
  table1:
    name: 'Peter'
  table2:
    phone: '%{random_phone}'
```

Pay attention that default placeholders are `random_date`, `hex_string`, `random_phone`, `fake_personal_id_number`, `random_amount`. You can add your own placeholders by supplying them to initializer ([see below](#custom_placeholders))

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

The case gem is used originally is data anonymization with accordance to data protection regulations in EU. Reducing the amount of sensitive information, after transactions are complete is the safest bet when it comes to data security.

This can be achieved through setting up a `sidekiq` worker:

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

Then you can use tool like `sidekiq-cron` in order to schedule it.

### Rake-task for using production data locally

Another use might be when a developer dumps a production database in order to play with it locally.

To be on the safe side and to not compromise sensitive data, the gem might be configured in the following way:

```YAML
config:
  retention_time:
    value: 0
    unit: 'seconds'

schema:
  # your anonymization schema
```

Then gem can be invoked from the rake-task. It is your responsibility to ensure that it never runs on production.

### Non-destructive use

Anonymizers might be used with collection `ActiveRecord::Relation` supplied, not affecting any database.

For example:

```ruby
anonymizer = ForgetThat::Service.new
collection = Address.where(created_at: Time.current - 40.days)
anonymizer.sanitize_collection(collection)
```

This will return an array of Hashes, corresponding to the records in `collection`. All fields configured to be anonymized, will be anonymized, ids will be stripped, the rest will be provided as is. This method ignores `retention_time`.

### Custom placeholders

The default placeholders are `random_date`, `hex_string`, `random_phone`, `fake_personal_id_number`, `random_amount`. In some cases this might not be enough or behaviour might not be desireable. In that case you can supply `anonymizers` hash.

```ruby
ForgetThat::Service.new(
  anonymizers: {
    foobar: -> { 'Foo' + 'Bar' }
  }
).call
```

Each member of this hash must be a zero-arity lambda that returns a string value.

If the key in the hash matches one of the pre-defined placeholders, the pre-defined placeholder will be overridden by the new one.

After anonymizer was supplied with the lambda, it can be used in the config.

```YAML
# ...

schema:
  users:
    name: 'Peter %{foobar}' #results in the "name" column of table "users" filled with "Peter FooBar"
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vehiculum-berlin/forget_that.
