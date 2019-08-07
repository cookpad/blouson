module Blouson
  module SensitiveMailLogFilter
    def deliver(event)
      e = ActiveSupport::Notifications::Event.new(
        event.name,
        event.time,
        event.end,
        event.transaction_id,
        event.payload.merge(
          to: Blouson::FILTERED,
          mail: "[Blouson::SensitiveMailLogFilter] Mail data is filtered for sensitive data"
        )
      )
      super(e)
    end
  end
end
