# frozen_string_literal: true

module StructuredData
  # https://schema.org/Event
  class Event < Thing
    properties :location, :organizer, :performer, :sub_event, :super_event
    date_properties :start_date, :end_date
    enum :event_status, %w[EventScheduled EventCancelled EventMovedOnline EventPostponed EventRescheduled]
    enum :event_attendance_mode,
         %w[OfflineEventAttendanceMode OnlineEventAttendanceMode MixedEventAttendanceMode]
  end
end
