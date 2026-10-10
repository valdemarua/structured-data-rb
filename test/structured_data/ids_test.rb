# frozen_string_literal: true

require "test_helper"

class IdsTest < Minitest::Test
  def setup
    @ids = StructuredData::Ids.new("https://example.com/")
  end

  def test_site_wide_ids
    assert_equal "https://example.com/#organization", @ids.organization
    assert_equal "https://example.com/#website", @ids.website
    assert_equal "https://example.com/#logo", @ids.site(:logo)
  end

  def test_page_resolves_paths_and_drops_fragments
    assert_equal "https://example.com/teams/rovers", @ids.page("/teams/rovers")
    assert_equal "https://example.com/teams/rovers", @ids.page("https://example.com/teams/rovers#roster")
  end

  def test_entity
    assert_equal "https://example.com/teams/rovers#team", @ids.entity("/teams/rovers", :team)
    assert_equal "https://example.com/news/a#article", @ids.entity("https://example.com/news/a", "article")
  end

  def test_base_url_with_a_path
    ids = StructuredData::Ids.new("https://example.com/blog")

    assert_equal "https://example.com/blog/#organization", ids.organization
    assert_equal "https://example.com/blog/posts/1", ids.page("/blog/posts/1")
  end

  def test_ids_work_as_entity_ids
    thing = TestEntities::Thing.new(id: @ids.entity("/teams/rovers", :team))

    assert_equal "https://example.com/teams/rovers#team", thing.ref.id
  end

  def test_invalid_base_url
    error = assert_raises(ArgumentError) { StructuredData::Ids.new("example.com") }

    assert_equal 'expected an absolute http(s) base URL, got "example.com"', error.message
  end

  def test_relative_path_without_leading_slash
    assert_raises(ArgumentError) { @ids.page("teams/rovers") }
  end

  def test_invalid_kind
    assert_raises(ArgumentError) { @ids.entity("/teams/rovers", "my team") }
  end
end
