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
      def initialize(message = nil, sql: nil, binds: nil, connection_pool: nil)
        if SensitiveQueryFilter.contain_sensitive_query?(message) || SensitiveQueryFilter.contain_sensitive_query?(sql)
          message = SensitiveQueryFilter.filter_sensitive_words(message) if message
          sql = SensitiveQueryFilter.filter_sensitive_words(sql) if sql
          if defined?(Mysql2::Error)
            if $!.is_a?(Mysql2::Error)
              $!.extend(Mysql2Filter)
            end
          end
        end

        super(message, sql:, binds:, connection_pool:)
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

    module AbstractAdapterFilter71
      # https://github.com/rails/rails/blob/v7.1.0/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L1133
      def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil, async: false, &block)
        super(sql, name, binds, type_casted_binds, statement_name, async:, &block)
      rescue ActiveRecord::RecordNotUnique, Mysql2::Error => ex
        if ex.cause.is_a?(Mysql2::Error)
          ex.cause.extend(Mysql2Filter)
        elsif $!.is_a?(Mysql2::Error)
          $!.extend(Mysql2Filter)
        end
        raise ex
      end
      private :log
    end

    module AbstractAdapterFilter80
      # https://github.com/rails/rails/blob/v8.0.0/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L1128
      def log(sql, name = "SQL", binds = [], type_casted_binds = [], async: false, &block)
        super(sql, name, binds, type_casted_binds, async:, &block)
      rescue ActiveRecord::RecordNotUnique, Mysql2::Error => ex
        if ex.cause.is_a?(Mysql2::Error)
          ex.cause.extend(Mysql2Filter)
        elsif $!.is_a?(Mysql2::Error)
          $!.extend(Mysql2Filter)
        end
        raise ex
      end
      private :log
    end

    module AbstractAdapterFilter81
      # https://github.com/rails/rails/blob/v8.1.0/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb#L1200
      def log(sql, name = "SQL", binds = [], type_casted_binds = [], async: false, allow_retry: false, &block)
        super(sql, name, binds, type_casted_binds, async:, allow_retry:, &block)
      rescue ActiveRecord::RecordNotUnique, Mysql2::Error => ex
        if ex.cause.is_a?(Mysql2::Error)
          ex.cause.extend(Mysql2Filter)
        elsif $!.is_a?(Mysql2::Error)
          $!.extend(Mysql2Filter)
        end
        raise ex
      end
      private :log
    end
  end
end
