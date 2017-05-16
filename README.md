# Blouson
[![Gem Version](https://badge.fury.io/rb/blouson.svg)](https://badge.fury.io/rb/blouson)
[![Build Status](https://travis-ci.org/cookpad/blouson.svg?branch=master)](https://travis-ci.org/cookpad/blouson)

Blouson is a filter tool for Rails to conceal sensitive data from various logs.

- HTTP Request parameters in Rails log
- SQL query in Rails log
- Exception messages in `ActiveRecord::StatementInvalid`
- Sentry Raven parameters

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blouson'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blouson

## Usage

### SensitiveParamsSilencer
If there is a HTTP request parameter prefixed with ```secure_```, Blouson conceals sensitive data from logging.
Blouson enables this filter automatically.

Example:
```
Started PUT "/employees/1" for 127.0.0.1 at Tue Jan 1 00:00:00 +0900 2013
Processing by EmployeesController#update as HTML
  Parameters: {"commit"=>"Update Employee", "id"=>"1", "employee"=>{"name"=>"", "secure_personal_information"=>"[FILTERED]"}, "utf8"=>"✓"}
  [Blouson::SensitiveParamsSilencer] SQL Log is skipped for sensitive data
```

### SensitiveQueryFilter
If there is a table prefixed with `secure_`, in exception message of `ActiveRecord::StatementInvalid`, Blouson conceals sensitive data from exception messages.
Blouson enables this filter automatically.

Example:

```
RuntimeError: error: SELECT  `secure_users`.* FROM `secure_users` WHERE `secure_users`.`email` = '[FILTERED]'  ORDER BY `secure_users`.`id` ASC LIMIT 1
```

### SensitiveTableQueryLogSilencer
Blouson provides an [Arproxy](https://github.com/cookpad/arproxy) module to suppress query logs for secure_ prefix tables. If there is a query log for `secure_` prefix table, Blouson conceals it.
This proxy does not works automatically, so that you have to set `Blouson::SensitiveTableQueryLogSilencer` in your Arproxy initializer.

```ruby
require 'blouson/sensitive_table_query_log_silencer'
# your initializers

Arproxy.configure do |config|
  config.adapter = "mysql2"
  config.use Blouson::SensitiveTableQueryLogSilencer
end
Arproxy.enable!
```

### RavenParameterFilterProcessor
Blouson provides an [Raven-Ruby](https://github.com/getsentry/raven-ruby) processor to conceal sensitive data from query string, request body, request headers and cookie values.

```ruby
require 'blouson/raven_parameter_filter_processor'

filter_pattern = Rails.application.config.filter_parameters
secure_headers = %w(secret_token)

Raven.configure do |config|
  ...
  config.processors = [Blouson::RavenParameterFilterProcessor.create(filter_pattern, secure_headers)]
  ...
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cookpad/blouson.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
