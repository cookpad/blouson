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
