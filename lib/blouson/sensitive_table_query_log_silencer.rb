module Blouson
  class SensitiveTableQueryLogSilencer < Arproxy::Base
    def execute(sql, name=nil)
      if Rails.logger.level != Logger::DEBUG || !(Blouson::SENSITIVE_TABLE_REGEXP === sql)
        return super(sql, name)
      end

      begin
        ActiveRecord::Base.logger.level = Logger::INFO
        Rails.logger.info "  [Blouson::SensitiveTableQueryLogSilencer] SQL Log is skipped for sensitive table"
        super(sql, name)
      ensure
        ActiveRecord::Base.logger.level = Logger::DEBUG
      end
    end
  end
end
