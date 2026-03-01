module Blouson
  class SentryParameterFilter
    def initialize(filters, header_filters = [])
      @parameter_filter = ActiveSupport::ParameterFilter.new(filters)
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
      req = event.request
      return unless req && req.data.present?

      data = req.data
      if data.is_a?(String)
        # Maybe JSON request
        begin
          data = JSON.parse(data)
          req.data = JSON.dump(@parameter_filter.filter(data))
        rescue JSON::ParserError => e
          # Record parser error to extra field
          event.extra['BlousonError'] = e.message
        end
      else
        req.data = @parameter_filter.filter(data)
      end
    end

    def process_query_string(event)
      req = event.request
      return unless req && req.query_string.present?

      query    = Rack::Utils.parse_query(req.query_string)
      filtered = @parameter_filter.filter(query)

      req.query_string = Rack::Utils.build_query(filtered)
    end

    def process_request_header(event)
      req = event.request
      return unless req && req.headers

      req.headers.each_key do |k|
        if @header_filters.include?(k.downcase)
          req.headers[k] = 'FILTERED'
        end
      end
    end

    def process_cookie(event)
      req = event.request
      return unless req

      if req.cookies
        req.cookies = @parameter_filter.filter(req.cookies)
      end

      if req.headers && req.headers['Cookie']
        cookies  = Hash[req.headers['Cookie'].split('; ').map { |pair| pair.split('=', 2) }]
        filtered = @parameter_filter.filter(cookies)

        req.headers['Cookie'] = filtered.map { |pair| pair.join('=') }.join('; ')
      end
    end
  end
end
