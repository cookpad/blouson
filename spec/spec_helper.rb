require "bundler/setup"
require 'pry'
require 'rails'
require 'mysql2'
require 'active_record'
require "blouson"

database_config = { 'adapter'  => 'mysql2', 'database' => 'blouson_test' }

class SecureUser < ActiveRecord::Base
end

class User < ActiveRecord::Base
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  config.warnings = false

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    ActiveRecord::Tasks::DatabaseTasks.create(database_config)
    ActiveRecord::Base.establish_connection(database_config)
    ActiveRecord::Base.connection.execute(
      <<-SQL.strip_heredoc
        CREATE TABLE `secure_users` (
          `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
          `email` varchar(255) NOT NULL,
          `email2` varchar(255) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `idx_email2` (`email2`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      SQL
    )
    ActiveRecord::Base.connection.execute(
      <<-SQL.strip_heredoc
        CREATE TABLE `users` (
          `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
          `name` varchar(255) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `idx_name` (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      SQL
    )
  end

  config.after(:suite) do
     ActiveRecord::Tasks::DatabaseTasks.drop(database_config)
  end
end
