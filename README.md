## Installation

Add the following to your `Gemfile`:

```ruby
gem 'influx_reporter', '~> 1.0.0'
```

The InfluxReporter gem adheres to [Semantic
Versioning](http://guides.rubygems.org/patterns/#semantic-versioning)
and so you can safely trust all minor and patch versions (e.g. 1.x.x) to
be backwards compatible.

## Usage

### Rails 3/4/5

Add the following to your `config/environments/production.rb`:

```ruby
Rails.application.configure do |config|
  # ...
  config.influx_reporter.database = 'endpoints'
  config.influx_reporter.influx_db = {
    host: 'influxdb.local',
    port: '8080'
  }
```

### Rack

```ruby
require 'influx_reporter'

# set up an InfluxReporter configuration
config = InfluxReporter::Configuration.new do |conf|
  conf.influx_reporter.database = 'endpoints'
  conf.influx_reporter.influx_db = {
      host: 'influxdb.local',
      port: '8080'
  }
  conf.tags = { 
    environment: ENV['RACK_ENV']
  }
end

# start the InfluxReporter client
InfluxReporter.start! config

# install the InfluxReporter middleware
use InfluxReporter::Middleware

```

## Configuration

InfluxReporter works with just the InfluxDB host configuration.

#### Enable in development and other environments

As a default InfluxReporter only runs in production. You can make it run in other environments by adding them to the `enabled_environments` whitelist.

```ruby
config.influx_reporter.enabled_environments += %w{development}
```

#### Ignore specific exceptions

```ruby
config.influx_reporter.excluded_exceptions += %w{
  ActiveRecord::RecordNotFound
  ActionController::RoutingError
}
```

### Sanitizing data

InfluxReporter can strip certain data points from the reports it sends like passwords or other sensitive information. If you're on Rails the list will automatically include what you have in `config.filter_parameters`.

Add or modify the list using the `filter_parameters` configuration:

```ruby
config.influx_reporter.filter_parameters += [/regex(p)?/, "string", :symbol]
```

### User information

InfluxReporter can automatically add user information to errors. By default it looks for at method called `current_user` on the current controller. To change the method use `current_user_method`.

```ruby
config.influx_reporter.current_user_method = :current_employee
```

### Error context

You may specify extra context for errors ahead of time by using `InfluxReporter.set_context` eg:

```ruby
class DashboardController < ApplicationController
  before_action do
    InfluxReporter.set_context(tags: { timezone: current_user.timezone }, values: { my_value: 11 })
  end
end
```

or by specifying it as a block using `InfluxReporter.with_context` eg:

```ruby
InfluxReporter.with_context(values: { user_id: @user.id }) do
  UserMailer.welcome_email(@user).deliver_now
end
```

### Transaction context
You may specify extra context for performance transaction

```ruby
InfluxReporter.client&.current_transaction&.extra_tags do |tags|
  tags[:locale] = I18n.locale
end
InfluxReporter.client&.current_transaction&.extra_values do |values|
  values[:uuid] = request.uuid
end
```


## Background processing

InfluxReporter automatically catches exceptions in [delayed_job](https://github.com/collectiveidea/delayed_job) or [sidekiq](http://sidekiq.org/).

To enable InfluxReporter for [resque](https://github.com/resque/resque), add the following (for example in `config/initializers/influx_reporter_resque.rb`):

```ruby
require "resque/failure/multiple"
require "influx_reporter/integration/resque"

Resque::Failure::Multiple.classes = [InfluxReporter::Integration::Resque]
Resque::Failure.backend = Resque::Failure::Multiple
```

## Sending events to Influx

You may want to send events instead of errors or performance traces to Influx. In this case, a method is provided:

```ruby
InfluxReporter.report_event 'event_name'
```

By default, the InfluxDB series name will be "events". You can change this with an extra parameter:
```ruby
InfluxReporter.report_event 'event_name', extra: { series: 'my_series' }
```

Adding tags & values is also possible:
```ruby
InfluxReporter.report_event 'event_name', extra: { tags: { key: 'tag' }, values: { key: 'value' } }
```

## Manual profiling

It's easy to add performance tracking wherever you want using the `InfluxReporter` module.

Basically you have to know about two concepts: `Transaction` and `Trace`.

**Transactions** are a bundles of transactions. In a typical webapp every request is wrapped in a transaction. If you're instrumenting worker jobs, a single job run would be a transaction.

**Traces** are spans of time that happen during a transaction. Like a call to the database, a render of a view or a HTTP request. InfluxReporter will automatically trace the libraries that it knows of and you can manually trace whatever else you'd like to.

The basic api looks like this:

```ruby
InfluxReporter.transaction "Transaction identifier" do
  data = InfluxReporter.trace "Preparation" do
    prepare_data
  end
  InfluxReporter.trace "Description", "kind" do
    perform_expensive_task data
  end
end.done(200)
```

If you are inside a web request, you are already inside a transaction so you only need to use trace:

```ruby
class UsersController < ApplicationController

  def extend_profiles
    users = User.all

    InfluxReporter.trace "prepare users" do
      users.each { |user| user.extend_profile! }
    end

    render text: 'ok'
  end

end
```

## Testing and development

```bash
$ bundle install
$ rspec spec
```

## Resources
