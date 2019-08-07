require 'spec_helper'

RSpec.describe Blouson::SensitiveMailLogFilter do
  it 'filters sensitive data' do
    klass = Class.new(ActiveSupport::Subscriber) do
      cattr_accessor :to, :mail
      def deliver(event)
        self.class.to = event.payload[:to]
        self.class.mail = event.payload[:mail]
      end
    end

    klass.attach_to :dummy
    klass.prepend Blouson::SensitiveMailLogFilter

    ActiveSupport::Notifications.instrument('deliver.dummy') do |payload|
      payload[:to] = "user@example.com"
      payload[:mail] = "To: user@example.com\n\nbody"
    end

    expect(klass.to).to eq Blouson::FILTERED
    expect(klass.mail).to match '[Blouson::SensitiveMailLogFilter]'
  end
end
