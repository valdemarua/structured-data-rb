# frozen_string_literal: true

require "test_helper"

class EntitiesTest < Minitest::Test
  include StructuredData

  def test_breadcrumb_list_from_pairs
    list = BreadcrumbList.from([["Home", "https://example.com/"], ["Teams", "https://example.com/teams"], ["Rovers"]])

    assert_equal(
      [
        { "@type" => "ListItem", "position" => 1, "name" => "Home", "item" => "https://example.com/" },
        { "@type" => "ListItem", "position" => 2, "name" => "Teams", "item" => "https://example.com/teams" },
        { "@type" => "ListItem", "position" => 3, "name" => "Rovers" }
      ],
      list.to_h["itemListElement"]
    )
  end

  def test_breadcrumb_list_from_accepts_other_properties
    list = BreadcrumbList.from([["Home", "https://example.com/"]], id: "https://example.com/#breadcrumb")

    assert_equal "https://example.com/#breadcrumb", list.id
  end

  def test_breadcrumb_list_from_checks_urls
    error = assert_raises(ValidationError) { BreadcrumbList.from([%w[Home /]]) }

    assert_equal 'ListItem item: expected an absolute http(s) URL, got "/"', error.message
  end

  def test_empty_breadcrumb_list_has_no_items
    assert_equal({ "@type" => "BreadcrumbList" }, BreadcrumbList.from([]).to_h)
  end

  def test_types_inherit_schema_org_properties
    team = SportsTeam.new(name: "Rovers", logo: "https://example.com/logo.png", sport: "Basketball",
                          founding_date: "1947", athlete: Person.new(name: "Sam Carter"))

    assert_equal %w[@type name logo sport foundingDate athlete], team.to_h.keys
  end

  def test_event_enums
    event = SportsEvent.new(event_status: "EventPostponed", event_attendance_mode: "OfflineEventAttendanceMode")

    assert_equal "https://schema.org/EventPostponed", event.to_h["eventStatus"]
    assert_equal "https://schema.org/OfflineEventAttendanceMode", event.to_h["eventAttendanceMode"]
  end

  def test_schema_type_is_the_class_name
    assert_equal %w[StadiumOrArena NewsArticle CollectionPage NewsMediaOrganization],
                 [StadiumOrArena, NewsArticle, CollectionPage, NewsMediaOrganization].map(&:schema_type)
  end

  def test_news_media_organization_is_an_organization
    publisher = NewsMediaOrganization.new(id: "https://example.com/#organization", name: "Example News",
                                          url: "https://example.com/", logo: "https://example.com/logo.png")

    assert_equal(
      { "@type" => "NewsMediaOrganization", "@id" => "https://example.com/#organization", "name" => "Example News",
        "url" => "https://example.com/", "logo" => "https://example.com/logo.png" },
      publisher.to_h
    )
  end
end
