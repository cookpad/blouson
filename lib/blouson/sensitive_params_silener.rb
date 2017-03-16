module Blouson
  class SensitiveParamsSilencer
    class << self
      def around(controller)
        if include_sensitive_data?(controller)
          begin
            old_level = ActiveRecord::Base.logger.level
            ActiveRecord::Base.logger.level = Logger::INFO
            Rails.logger.info "  [Blouson::SensitiveParamsSilencer] SQL Log is skipped for sensitive data"
            yield
          ensure
            ActiveRecord::Base.logger.level = old_level
          end
        else
          yield
        end
      end

      def include_sensitive_data?(controller)
        nested_params_keys(controller.params).any? { |key, value| Blouson::SENSITIVE_PARAMS_REGEXP === key }
      end

      private :include_sensitive_data?

      def nested_params_keys(params)
        if params.respond_to?(:to_unsafe_h)
          params = params.to_unsafe_h
        end
        user_params = params.reject { |key, value| 'controller' == key || 'action' == key }
        user_params.inject([]) do |keys, pair|
          keys << pair.first
          keys += pair.last.keys if pair.last.kind_of? Hash
          keys
        end
      end

      private :nested_params_keys
    end
  end
end
