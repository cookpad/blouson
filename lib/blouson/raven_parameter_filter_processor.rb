module Blouson
  class RavenParameterFilterProcessor
    def self.create(filters, header_filters)
      Class.new(Raven::Processor) do
        @filters = filters
        @header_filters = header_filters.map(&:downcase)

        def self.filters
          @filters
        end

        def self.header_filters
          @header_filters
        end

        def initialize(client = nil)
          # ActionDispatch::Http::ParameterFilter is deprecated and will be removed from Rails 6.1.
          parameter_filter_klass = if defined?(ActiveSupport::ParameterFilter)
              ActiveSupport::ParameterFilter
            else
              ActionDispatch::Http::ParameterFilter
            end
          @parameter_filter = parameter_filter_klass.new(self.class.filters)
        end

        def process(value)
          process_query_string(value)
          process_request_body(value)
          process_request_header(value)
          process_cookie(value)
        ensure
          return value
        end

        def process_request_body(value)
          if value[:request] && value[:request][:data].present?
            data = value[:request][:data]
            if data.is_a?(String)
              # Maybe JSON request
              begin
                data = JSON.parse(data)
                value[:request][:data] = JSON.dump(@parameter_filter.filter(data))
              rescue JSON::ParserError => e
                # Record parser error to extra field
                value[:extra]['BlousonError'] = e.message
              end
            else
              value[:request][:data] = @parameter_filter.filter(data)
            end
          end
        end

        def process_query_string(value)
          if value[:request] && value[:request][:query_string].present?
            query    = Rack::Utils.parse_query(value[:request][:query_string])
            filtered = @parameter_filter.filter(query)

            value[:request][:query_string] = Rack::Utils.build_query(filtered)
          end
        end

        def process_request_header(value)
          if value[:request] && value[:request][:headers]
            headers = value[:request][:headers]
            headers.each_key do |k|
              if self.class.header_filters.include?(k.downcase)
                headers[k] = 'FILTERED'
              end
            end
          end
        end

        def process_cookie(value)
          if (cookies = value.dig(:request, :cookies))
            value[:request][:cookies] = @parameter_filter.filter(cookies)
          end

          if value[:request] && value[:request][:headers] && value[:request][:headers]['Cookie']
            cookies  = Hash[value[:request][:headers]['Cookie'].split('; ').map { |pair| pair.split('=', 2) }]
            filtered = @parameter_filter.filter(cookies)

            value[:request][:headers]['Cookie'] = filtered.map { |pair| pair.join('=') }.join('; ')
          end
        end
      end
    end
  end
end
