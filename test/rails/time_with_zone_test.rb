# frozen_string_literal: true

require "test_helper"
require "active_support"
require "active_support/time"

class TimeWithZoneTest < Minitest::Test
  def test_time_with_zone_keeps_its_offset
    time = ActiveSupport::TimeZone["America/New_York"].local(2026, 10, 14, 19, 30)
    event = TestEntities::Event.new(start_date: time)

    assert_equal "2026-10-14T19:30:00-04:00", event.to_h["startDate"]
  end
end
