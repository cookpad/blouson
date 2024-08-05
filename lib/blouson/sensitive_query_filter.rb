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
      def initialize(message = nil, original_exception = nil, sql: nil, binds: nil, connection_pool: nil)
        if SensitiveQueryFilter.contain_sensitive_query?(message) || (SensitiveQueryFilter.contain_sensitive_query?(sql))
          message = SensitiveQueryFilter.filter_sensitive_words(message) if message
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
        elsif connection_pool
          # Rails >= 7.1
          #
          # - https://github.com/rails/rails/pull/48295
          super(message, sql: sql, binds: binds, connection_pool: connection_pool)
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

      def set_query(sql, binds)
        if SensitiveQueryFilter.contain_sensitive_query?(sql)
          super(SensitiveQueryFilter.filter_sensitive_words(sql), binds)
        else
          super(sql, binds)
        end
      end

      def to_s
        if SensitiveQueryFilter.contain_sensitive_query?(sql)
          SensitiveQueryFilter.filter_sensitive_words(super)
        else
          super
        end
      end
    end

    module Mysql2Filter
      def message
        SensitiveQueryFilter.filter_sensitive_words(super)
      end
    end

    module AbstractAdapterFilter
      def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil, async: false, &block)
        super(sql, name, binds, type_casted_binds, statement_name, async: false, &block)
      rescue ActiveRecord::RecordNotUnique, Mysql2::Error => ex
        if ex.cause.is_a?(Mysql2::Error)
          ex.cause.extend(Mysql2Filter)
        elsif $!.is_a?(Mysql2::Error)
          $!.extend(Mysql2Filter)
        end
        raise ex.set_query(sql, binds)
      end

      private :log
    end
    end
end
