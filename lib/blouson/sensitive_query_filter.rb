module Blouson
  module SensitiveQueryFilter
    QUOTED_WORD_REGEXP = /
      (?: '.+?(?<!\\)'
        | ".+?(?<!\\)"
      )
    /x

    def self.contain_sensitive_query?(message)
      Blouson::SENSITIVE_TABLE_REGEXP === message
    end

    def self.filter_sensitive_words(message)
      message.gsub(QUOTED_WORD_REGEXP, "'#{Blouson::FILTERED}'")
    end

    module StatementInvalidErrorFilter
      def initialize(message = nil, original_exception = nil, sql: nil, binds: nil)
        if SensitiveQueryFilter.contain_sensitive_query?(message) || (sql && SensitiveQueryFilter.contain_sensitive_query?(sql))
          message = SensitiveQueryFilter.filter_sensitive_words(message)
          sql = SensitiveQueryFilter.filter_sensitive_words(sql) if sql
          if defined?(Mysql2::Error)
            if original_exception.is_a?(Mysql2::Error)
              original_exception.extend(Mysql2Filter)
            elsif $!.is_a?(Mysql2::Error)
              $!.extend(Mysql2Filter)
            end
          end
        end

        if original_exception
          # Rails < 5.0
          super(message, original_exception)
        elsif sql
          # Rails >= 6.0
          #
          # - https://github.com/rails/rails/pull/34468
          super(message, sql: sql, binds: binds)
        else
          # Rails >= 5.0
          #
          # - https://github.com/rails/rails/pull/18774
          # - https://github.com/rails/rails/pull/27503
          super(message)
        end
      end
    end

    module Mysql2Filter
      def message
        SensitiveQueryFilter.filter_sensitive_words(super)
      end
    end
  end
end
