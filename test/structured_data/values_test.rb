# frozen_string_literal: true

require "test_helper"

class ValuesTest < Minitest::Test
  Thing = TestEntities::Thing
  Event = TestEntities::Event

  def test_time_keeps_its_offset
    event = Event.new(start_date: Time.new(2026, 10, 14, 19, 30, 0, "-04:00"))

    assert_equal "2026-10-14T19:30:00-04:00", event.to_h["startDate"]
  end

  def test_date_and_datetime
    assert_equal "2026-10-14", Event.new(start_date: Date.new(2026, 10, 14)).to_h["startDate"]
    assert_equal "2026-10-14T19:30:00+00:00",
                 Event.new(start_date: DateTime.new(2026, 10, 14, 19, 30)).to_h["startDate"]
  end

  def test_any_object_with_iso8601_is_a_date
    time_like = Struct.new(:value) { def iso8601 = value }.new("2026-10-14T19:30:00+03:00")

    assert_equal "2026-10-14T19:30:00+03:00", Event.new(start_date: time_like).to_h["startDate"]
  end

  def test_iso_8601_strings_including_partial_dates
    ["1947", "2026-09", "2026-09-25", "2026-09-25T08:33", "2026-09-25T08:33:00Z",
     "2026-09-25T08:33:00.123+03:00"].each do |value|
      assert_equal value, Event.new(start_date: value).to_h["startDate"]
    end
  end

  def test_malformed_date_string
    error = assert_raises(StructuredData::ValidationError) { Event.new(start_date: "tomorrow") }

    assert_equal 'Event start_date: expected an ISO 8601 date, got "tomorrow"', error.message
  end

  def test_absolute_urls_including_non_ascii
    url = "https://example.com/équipes/café?x=1#top"

    assert_equal url, Thing.new(url: url).to_h["url"]
  end

  def test_relative_url
    error = assert_raises(StructuredData::ValidationError) { Thing.new(url: "/teams/rovers") }

    assert_equal 'Thing url: expected an absolute http(s) URL, got "/teams/rovers"', error.message
  end

  def test_invalid_url_in_array_names_the_index
    error = assert_raises(StructuredData::ValidationError) do
      Thing.new(image: ["https://example.com/a.png", "ftp://example.com/b.png"])
    end

    assert_equal 'Thing image[1]: expected an absolute http(s) URL, got "ftp://example.com/b.png"', error.message
  end

  def test_url_property_accepts_an_entity
    image = Thing.new(url: "https://example.com/a.png")

    assert_equal "Thing", Thing.new(image: image).to_h.dig("image", "@type")
  end

  def test_enum_expands_to_schema_org_url
    assert_equal "https://schema.org/EventScheduled", Event.new(event_status: "EventScheduled").to_h["eventStatus"]
  end

  def test_unknown_enum_member
    error = assert_raises(StructuredData::ValidationError) { Event.new(event_status: "Finished") }

    assert_equal 'Event event_status: expected one of EventScheduled, EventCancelled, got "Finished"', error.message
  end

  def test_unknown_property
    error = assert_raises(StructuredData::UnknownPropertyError) { Thing.new(name: "Rovers", team: "x") }

    assert_equal "Thing does not support property :team", error.message
  end

  def test_unsupported_value_kind
    error = assert_raises(StructuredData::ValidationError) { Thing.new(name: { "@id" => "x" }) }

    assert_equal "Thing name: expected text, a number, a boolean, a date, an entity or a reference, got Hash",
                 error.message
  end

  def test_numbers_are_rejected_for_url_and_enum_properties
    assert_raises(StructuredData::ValidationError) { Thing.new(url: 42) }
    assert_raises(StructuredData::ValidationError) { Event.new(event_status: true) }
  end

  def test_non_finite_numbers
    error = assert_raises(StructuredData::ValidationError) { Thing.new(rating: Float::NAN) }

    assert_equal "Thing rating: expected a finite number, got NaN", error.message
  end
end
