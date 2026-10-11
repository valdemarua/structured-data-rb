# frozen_string_literal: true

require "test_helper"

# Builds each golden fixture with the public API and compares the JSON text, so key order counts.
# Regenerate with UPDATE_FIXTURES=1 and review the diff.
class FixturesTest < Minitest::Test
  include StructuredData

  IDS = Ids.new("https://example.com")

  def test_news_article
    article_url = "https://example.com/news/rovers-sign-new-head-coach"
    organization = Organization.new(
      id: IDS.organization,
      name: "Example Sports News",
      url: "https://example.com/",
      logo: ImageObject.new(url: "https://example.com/images/logo.png", width: 512, height: 512)
    )
    website = WebSite.new(
      id: IDS.website, name: "Example Sports News", url: "https://example.com/",
      publisher: organization.ref, in_language: "en"
    )
    breadcrumbs = BreadcrumbList.from(
      [["Home", "https://example.com/"], ["News", "https://example.com/news"], ["Rovers sign a new head coach"]],
      id: IDS.entity(article_url, :breadcrumb)
    )
    article = NewsArticle.new(
      id: IDS.entity(article_url, :article),
      description: "Riverside Rovers have appointed Alex Morgan as head coach on a three-year contract.",
      url: article_url,
      image: "https://example.com/images/news/rovers-coach.jpg",
      main_entity_of_page: article_url,
      headline: "Rovers sign a new head coach",
      author: Person.new(name: "Jane Doe", url: "https://example.com/authors/jane-doe"),
      publisher: organization.ref,
      date_published: Time.new(2026, 9, 25, 8, 33, 0, "+03:00"),
      date_modified: Time.new(2026, 9, 25, 10, 5, 0, "+03:00"),
      in_language: "en",
      is_part_of: website.ref,
      about: [
        Ref.new(IDS.entity("/teams/riverside-rovers", :team)),
        Ref.new(IDS.entity("/people/alex-morgan", :person))
      ],
      article_section: "Transfers"
    )

    assert_fixture "news_article", organization, website, breadcrumbs, article
  end

  def test_sports_team
    team = SportsTeam.new(
      id: IDS.entity("/teams/riverside-rovers", :team),
      name: "Riverside Rovers",
      alternate_name: "Rovers",
      url: "https://example.com/teams/riverside-rovers",
      logo: "https://example.com/images/teams/riverside-rovers.png",
      founding_date: "1947",
      location: StadiumOrArena.new(name: "Riverside Arena"),
      member_of: league,
      sport: "Basketball",
      athlete: [
        person("sam-carter", "Sam Carter", image: "https://example.com/images/people/sam-carter.png",
                                           birth_date: Date.new(2001, 3, 4)),
        person("lee-park", "Lee Park", birth_date: Date.new(1999, 11, 20))
      ],
      coach: person("alex-morgan", "Alex Morgan")
    )

    assert_fixture "sports_team", team
  end

  def test_sports_event
    event = SportsEvent.new(
      id: IDS.entity("/games/1042", :event),
      name: "Riverside Rovers vs Harbor City Hawks",
      url: "https://example.com/games/1042",
      start_date: Time.new(2026, 10, 14, 19, 30, 0, "-04:00"),
      event_status: "EventScheduled",
      location: StadiumOrArena.new(name: "Riverside Arena"),
      organizer: league.ref,
      sport: "Basketball",
      home_team: team("riverside-rovers", "Riverside Rovers"),
      away_team: team("harbor-city-hawks", "Harbor City Hawks")
    )

    assert_fixture "sports_event", event
  end

  def test_movie
    movie = Movie.new(
      id: IDS.entity("/movies/the-long-season", :movie),
      name: "The Long Season",
      url: "https://example.com/movies/the-long-season",
      image: "https://example.com/images/movies/the-long-season.jpg",
      date_created: Date.new(2025, 5, 16),
      genre: %w[Drama Sport],
      director: Person.new(name: "Chris Lane"),
      actor: [Person.new(name: "Robin Hale"), Person.new(name: "Pat Quinn")],
      duration: "PT2H8M",
      aggregate_rating: AggregateRating.new(rating_value: 8.1, best_rating: 10, rating_count: 12_345)
    )

    assert_fixture "movie", movie
  end

  private

  def league
    SportsOrganization.new(
      id: IDS.entity("/leagues/national-league", :organization),
      name: "National League",
      url: "https://example.com/leagues/national-league",
      sport: "Basketball"
    )
  end

  def person(slug, name, **properties)
    Person.new(id: IDS.entity("/people/#{slug}", :person), name: name, url: "https://example.com/people/#{slug}",
               **properties)
  end

  def team(slug, name)
    SportsTeam.new(id: IDS.entity("/teams/#{slug}", :team), name: name, url: "https://example.com/teams/#{slug}")
  end

  def assert_fixture(name, *entities)
    path = File.expand_path("../fixtures/#{name}.json", __dir__)
    actual = "#{JSON.pretty_generate(StructuredData.graph(*entities))}\n"
    File.write(path, actual) if ENV["UPDATE_FIXTURES"]

    assert_equal File.read(path), actual
  end
end
