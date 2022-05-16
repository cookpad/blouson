module Blouson
  class SentryParameterFilter
    def initialize(filters, header_filters = [])
      # ActionDispatch::Http::ParameterFilter is deprecated and will be removed from Rails 6.1.
      parameter_filter_klass = if defined?(ActiveSupport::ParameterFilter)
                                 ActiveSupport::ParameterFilter
                               else
                                 ActionDispatch::Http::ParameterFilter
                               end
      @parameter_filter = parameter_filter_klass.new(filters)
      @header_filters = header_filters.map(&:downcase)
    end

    def process(event)
      process_query_string(event)
      process_request_body(event)
      process_request_header(event)
      process_cookie(event)
    ensure
      return event
    end

    private

    def process_request_body(event)
      if event[:request] && event[:request][:data].present?
        data = event[:request][:data]
        if data.is_a?(String)
          # Maybe JSON request
          begin
            data = JSON.parse(data)
            event[:request][:data] = JSON.dump(@parameter_filter.filter(data))
          rescue JSON::ParserError => e
            # Record parser error to extra field
            event[:extra]['BlousonError'] = e.message
          end
        else
          event[:request][:data] = @parameter_filter.filter(data)
        end
      end
    end

    def process_query_string(event)
      if event[:request] && event[:request][:query_string].present?
        query    = Rack::Utils.parse_query(event[:request][:query_string])
        filtered = @parameter_filter.filter(query)

        event[:request][:query_string] = Rack::Utils.build_query(filtered)
      end
    end

    def process_request_header(event)
      if event[:request] && event[:request][:headers]
        headers = event[:request][:headers]
        headers.each_key do |k|
          if @header_filters.include?(k.downcase)
            headers[k] = 'FILTERED'
          end
        end
      end
    end

    def process_cookie(event)
      if (cookies = event.dig(:request, :cookies))
        event[:request][:cookies] = @parameter_filter.filter(cookies)
      end

      if event[:request] && event[:request][:headers] && event[:request][:headers]['Cookie']
        cookies  = Hash[event[:request][:headers]['Cookie'].split('; ').map { |pair| pair.split('=', 2) }]
        filtered = @parameter_filter.filter(cookies)

        event[:request][:headers]['Cookie'] = filtered.map { |pair| pair.join('=') }.join('; ')
      end
    end
  end
end
