# Blouson
[![Gem Version](https://badge.fury.io/rb/blouson.svg)](https://badge.fury.io/rb/blouson)
[![Build Status](https://github.com/cookpad/blouson/actions/workflows/ci.yml/badge.svg)](https://github.com/cookpad/blouson/actions/workflows/ci.yml)

Blouson is a filter tool for Rails to conceal sensitive data from various logs.

- HTTP Request parameters in Rails log
- SQL query in Rails log
- Exception messages in `ActiveRecord::StatementInvalid`
- Sentry Raven parameters
- Mail parameters in Rails log

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
  config.processors << Blouson::RavenParameterFilterProcessor.create(filter_pattern, secure_headers)
  ...
end
```

### SensitiveMailLogFilter
ActionMailer outputs email address, all headers, and body text to the log when sending email.

```
D, [2019-08-08T08:40:15.939251 #67674] DEBUG -- : UserMailer#hello: processed outbound mail in 43.0ms
I, [2019-08-08T08:40:15.946281 #67674]  INFO -- : Sent mail to xxx@example.com (6.3ms)
D, [2019-08-08T08:40:15.946432 #67674] DEBUG -- : Date: Thu, 08 Aug 2019 08:40:15 +0900
From: from@example.com
To: xxx@example.com
Message-ID: <xxx>
Subject: Hello
Mime-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 7bit

Example mail.
```

Blouson filters such logs.

Example:

```
D, [2019-08-08T08:47:06.524182 #67886] DEBUG -- : UserMailer#hello: processed outbound mail in 23.2ms
I, [2019-08-08T08:47:06.530849 #67886]  INFO -- : Sent mail to [FILTERED] (6.4ms)
D, [2019-08-08T08:47:06.530953 #67886] DEBUG -- : [Blouson::SensitiveMailLogFilter] Mail data is filtered for sensitive data
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cookpad/blouson.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
