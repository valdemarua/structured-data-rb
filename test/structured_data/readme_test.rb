# frozen_string_literal: true

require "test_helper"

# Keeps the output shown at the top of README.md in sync with the gem.
class ReadmeTest < Minitest::Test
  def test_first_example_output
    article = StructuredData::NewsArticle.new(
      headline: "City council approves new bike lanes",
      url: "https://example.com/news/bike-lanes",
      date_published: Time.new(2026, 9, 25, 8, 33, 0, "+03:00"),
      in_language: "en",
      publisher: StructuredData::Organization.new(name: "Example News", url: "https://example.com/")
    )
    readme = File.read(File.expand_path("../../README.md", __dir__))

    assert_equal readme[/```json\n(.*?)\n```/m, 1], StructuredData.json_ld(article)
  end
end
