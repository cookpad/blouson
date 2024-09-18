# 3.0.0 (2024-09-18)
- [Breaking change] Drop support for Ruby 2.6
- [Breaking change] Drop support for Rails 5.0, 5.1, and 5.2
- Support Ruby 3.2 and 3.3
- Support Rails 7.1
- [Breaking change] blouson/sensitive_params_silener is renamed to blouson/sensitive_params_silencer
- Use `Rails.logger.debug?` for loggers other than the default Logger class
- Run tests with MySQL 8.4 instead of 5.7
- Ignore lockfiles for Appraisal for the development

# 2.0.0 (2022-05-23)
- Support parameter filter for `sentry-ruby` gem
- [Breaking change] Drop dependency of `sentry-raven` gem

# 1.1.4 (2022-05-02)
- Fix ArgumentError on activerecord 7.0

# 1.1.3 (2020-12-11)
- Fix cookies not being filtered when used with Raven::Rack

# 1.1.2 (2019-10-24)
- Support Rails 6.0

# 1.1.1 (2019-09-27)
- Change to use ActiveSupport::LoggerSilence for thread safety #10

# 1.1.0 (2019-08-09)
- Add feature to filter sensitive mail logs.

# 1.0.3 (2018-12-18)
- Fix Blouson::SensitiveQueryFilter::StatementInvalidErrorFilter for exceptions created with no arguments (like ActiveRecord::NoDatabaseError)

# 1.0.2 (2017-09-21)
- Change Raven filter's secure_headers config to be case insensitive https://github.com/cookpad/blouson/pull/4

# 1.0.1 (2017-05-16)
- Support Rails 5.1

# 1.0.0 (2017-03-16)
- Initial release
