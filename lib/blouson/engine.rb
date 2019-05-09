module Blouson
  class Engine < Rails::Engine
    initializer 'blouson.configure_rails_initialization' do |app|
      app.config.filter_parameters << Blouson::SENSITIVE_PARAMS_REGEXP
    end

    # We have to prevent logging sensitive data in SQL if production mode and logger level is debug
    initializer 'blouson.load_helpers' do |app|
      # Don't need to set hook when active_record is not required
      if !Rails.env.development? && Rails.logger.level == Logger::DEBUG && defined?(ActiveRecord)
        ActiveSupport.on_load(:action_controller) do
          around_action Blouson::SensitiveParamsSilencer
        end
      end
    end

    initializer 'blouson.set_sensitive_query_filter' do
      if Rails.env.production? || Rails.env.staging? || ENV['ENABLE_SENSITIVE_QUERY_FILTER'] == '1'
        ActiveSupport.on_load(:active_record) do
          ActiveRecord::StatementInvalid.class_eval do
            prepend Blouson::SensitiveQueryFilter::StatementInvalidErrorFilter
          end
        end
      end
    end
  end
end
