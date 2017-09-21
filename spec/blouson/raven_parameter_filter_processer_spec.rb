require 'spec_helper'
require 'raven'
require 'blouson/raven_parameter_filter_processor'

RSpec.describe 'Blouson::RavenParameterFilterProcessor' do
  describe 'process_request_headers' do
    let(:filter_processor_class) {
      Blouson::RavenParameterFilterProcessor.create(
        [],
        %w(Really-Sensitive-Header-That-Needs-To-Be-Filtered)
      )
    }

    let(:value) {
      {
        request: {
          headers: {
            'Really-Sensitive-Header-That-Needs-To-Be-Filtered' => 'important_token',
            'Insensitive-Header' => 'foo'
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
  end
end
