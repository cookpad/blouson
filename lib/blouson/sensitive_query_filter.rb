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
      def initialize(message, original_exception = nil)
        if SensitiveQueryFilter.contain_sensitive_query?(message)
          message = SensitiveQueryFilter.filter_sensitive_words(message)
          if defined?(Mysql2::Error)
            if original_exception.is_a?(Mysql2::Error)
              original_exception.extend(Mysql2Filter)
            elsif $!.is_a?(Mysql2::Error)
              $!.extend(Mysql2Filter)
            end
          end
        end
        super(message, original_exception)
      end
    end

    module Mysql2Filter
      def message
        SensitiveQueryFilter.filter_sensitive_words(super)
      end
    end
  end
end
