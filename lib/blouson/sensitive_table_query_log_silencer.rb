module Blouson
  class SensitiveTableQueryLogSilencer < Arproxy::Base
    def execute(sql, name=nil, **kwargs)
      if Rails.logger.level != Logger::DEBUG || !(Blouson::SENSITIVE_TABLE_REGEXP === sql)
        return super(sql, name, **kwargs)
      end

      ActiveRecord::Base.logger.silence(Logger::INFO) do
        Rails.logger.info "  [Blouson::SensitiveTableQueryLogSilencer] SQL Log is skipped for sensitive table"
        super(sql, name, **kwargs)
      end
    end
  end
end
