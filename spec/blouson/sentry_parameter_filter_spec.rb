require 'spec_helper'
require 'sentry-ruby'
require 'blouson/sentry_parameter_filter'

RSpec.describe Blouson::SentryParameterFilter do
  let(:filters) { ['sensitive-data'] }
  let(:header_filters) { %w(Really-Sensitive-Header-That-Needs-To-Be-Filtered) }
  let(:filter_class) { described_class.new(filters, header_filters) }

  let(:event) do
    {
      request: {
        headers: {
          'Really-Sensitive-Header-That-Needs-To-Be-Filtered' => 'important_token',
          'Insensitive-Header' => 'foo',
          'Cookie' => 'sensitive-data=secret-value; foo=non-secret-value'
        },
        cookies: {
          'sensitive-data' => 'secret-value',
          'foo' => 'non-secret-value'
        },
        data: "{\"sensitive-data\":\"secret-value\",\"normal-data\": {\"some-sensitive-data\":\"secret-value\"}}",
        query_string: 'sensitive-data=secret-value&normal-data=non-secret-value',
      }
    }
  end

  describe 'process_request_body' do
    it 'filters request body in the filters' do
      processed_event = filter_class.process(event)
      data = JSON.parse(processed_event[:request][:data])
      expect(data['sensitive-data']).to eq('[FILTERED]')
    end

    it 'do not filters request body not in the filters but nested value is filtered' do
      processed_event = filter_class.process(event)
      data = JSON.parse(processed_event[:request][:data])
      expect(data['normal-data']).to eq({ 'some-sensitive-data' => '[FILTERED]' })
    end
  end

  describe 'process_query_string' do
    it 'filters query string in the filters' do
      processed_event = filter_class.process(event)
      query = Rack::Utils.parse_query(processed_event[:request][:query_string])
      expect(query['sensitive-data']).to eq('[FILTERED]')
    end

    it 'do not filters query string not in the filters' do
      processed_event = filter_class.process(event)
      query = Rack::Utils.parse_query(processed_event[:request][:query_string])
      expect(query['normal-data']).to eq('non-secret-value')
    end
  end

  describe 'process_request_header' do
    it 'filters headers in the header_filters' do
      processed_event = filter_class.process(event)
      expect(processed_event[:request][:headers]['Really-Sensitive-Header-That-Needs-To-Be-Filtered']).to eq('FILTERED')
    end

    it 'do not filter headers not in header_filters' do
      processed_event = filter_class.process(event)
      expect(processed_event[:request][:headers]['Insensitive-Header']).to eq('foo')
    end
  end

  describe 'process_cookie' do
    it 'filters values in cookie in filters' do
      processed_event = filter_class.process(event)
      expect(processed_event[:request][:cookies]['sensitive-data']).to eq('[FILTERED]')
      expect(processed_event[:request][:cookies]['foo']).to eq('non-secret-value')
      expect(processed_event[:request][:headers]['Cookie']).to eq('sensitive-data=[FILTERED]; foo=non-secret-value')
    end
  end
end
