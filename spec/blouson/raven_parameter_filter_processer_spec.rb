require 'spec_helper'
require 'raven'
require 'blouson/raven_parameter_filter_processor'

RSpec.describe 'Blouson::RavenParameterFilterProcessor' do
  describe 'process_request_headers' do
    let(:filter_processor_class) {
      Blouson::RavenParameterFilterProcessor.create(
        ['sensitive-data'],
        %w(Really-Sensitive-Header-That-Needs-To-Be-Filtered)
      )
    }

    let(:value) {
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
          }
        }
      }
    }

    it 'filters headers in header_filters' do
      processed_value = filter_processor_class.new.process(value)
      expect(processed_value[:request][:headers]['Really-Sensitive-Header-That-Needs-To-Be-Filtered']).to eq('FILTERED')
    end

    it 'won\'t filter headers not in header_filters' do
      processed_value = filter_processor_class.new.process(value)
      expect(processed_value[:request][:headers]['Insensitive-Header']).to eq('foo')
    end

    it 'masks values of cookies whose names match the specified filters' do
      processed_value = filter_processor_class.new.process(value)
      expect(processed_value[:request][:cookies]['sensitive-data']).to eq('[FILTERED]')
      expect(processed_value[:request][:cookies]['foo']).to eq('non-secret-value')
      expect(processed_value[:request][:headers]['Cookie']).to eq('sensitive-data=[FILTERED]; foo=non-secret-value')
    end
  end
end
