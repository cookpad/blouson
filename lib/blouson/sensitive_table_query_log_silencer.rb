module Blouson
  class SensitiveTableQueryLogSilencer < Arproxy::Proxy
    def execute(sql, context)
      if !Rails.logger.debug? || !(Blouson::SENSITIVE_TABLE_REGEXP === sql)
        return super(sql, context)
      end

      ActiveRecord::Base.logger.silence(Logger::INFO) do
        Rails.logger.info "  [Blouson::SensitiveTableQueryLogSilencer] SQL Log is skipped for sensitive table"
        super(sql, context)
      end
    end
  end
end
