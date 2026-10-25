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
    assert_equal %w[StadiumOrArena NewsArticle CollectionPage NewsMediaOrganization TVSeries TVSeason TVEpisode],
                 [StadiumOrArena, NewsArticle, CollectionPage, NewsMediaOrganization, TVSeries, TVSeason,
                  TVEpisode].map(&:schema_type)
  end

  def test_image_and_video_objects_are_media_objects
    image = ImageObject.new(content_url: "https://example.com/a.jpg", width: 800, caption: "A photo")
    video = VideoObject.new(name: "Trailer", thumbnail_url: "https://example.com/a.jpg", upload_date: "2026-01-02",
                            embed_url: "https://example.com/embed/1", duration: "PT1M")

    assert_equal %w[@type contentUrl width caption], image.to_h.keys
    assert_equal %w[@type name thumbnailUrl uploadDate embedUrl duration], video.to_h.keys
  end

  def test_video_object_checks_upload_date
    error = assert_raises(ValidationError) { VideoObject.new(upload_date: "yesterday") }

    assert_equal 'VideoObject upload_date: expected an ISO 8601 date, got "yesterday"', error.message
  end

  def test_person_death_date
    person = Person.new(name: "Jane Doe", birth_date: Date.new(1931, 5, 4), death_date: Date.new(2020, 1, 9))

    assert_equal "2020-01-09", person.to_h["deathDate"]
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
