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
                                           birth_date: Date.new(2001, 3, 4),
                                           height: QuantitativeValue.new(value: 198, unit_code: "CMT"),
                                           weight: QuantitativeValue.new(value: 95, unit_code: "KGM")),
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
      location: StadiumOrArena.new(
        name: "Riverside Arena",
        address: PostalAddress.new(address_locality: "Riverside", address_region: "CA", address_country: "US")
      ),
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
      content_rating: "PG-13",
      trailer: trailer("the-long-season", "The Long Season: official trailer", Date.new(2025, 3, 2)),
      aggregate_rating: AggregateRating.new(rating_value: 8.1, best_rating: 10, rating_count: 12_345)
    )

    assert_fixture "movie", movie
  end

  def test_tv_episode
    series = TVSeries.new(
      id: IDS.entity("/series/harbor-lights", :series),
      name: "Harbor Lights",
      url: "https://example.com/series/harbor-lights",
      image: "https://example.com/images/series/harbor-lights.jpg",
      genre: "Drama",
      content_rating: "TV-14",
      start_date: "2023-09-12",
      end_date: "2025-06-03",
      number_of_seasons: 3,
      actor: Person.new(name: "Robin Hale", birth_date: "1948-02-11", death_date: "2024-12-30"),
      trailer: trailer("harbor-lights", "Harbor Lights: series trailer", Date.new(2023, 8, 1))
    )
    season = TVSeason.new(
      id: IDS.entity("/series/harbor-lights/season-2", :season),
      name: "Season 2",
      url: "https://example.com/series/harbor-lights/season-2",
      season_number: 2,
      number_of_episodes: 10,
      start_date: "2024-09-10",
      part_of_series: series.ref
    )
    episode = TVEpisode.new(
      id: IDS.entity("/series/harbor-lights/season-2/episode-3", :episode),
      name: "Low Tide",
      url: "https://example.com/series/harbor-lights/season-2/episode-3",
      episode_number: 3,
      date_published: Date.new(2024, 9, 24),
      duration: "PT52M",
      director: Person.new(name: "Chris Lane"),
      part_of_season: season.ref,
      part_of_series: series.ref
    )

    assert_fixture "tv_episode", series, season, episode
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

  def trailer(slug, name, upload_date)
    VideoObject.new(
      name: name,
      thumbnail_url: "https://example.com/images/trailers/#{slug}.jpg",
      upload_date: upload_date,
      description: "#{name}.",
      content_url: "https://example.com/videos/trailers/#{slug}.mp4",
      embed_url: "https://example.com/embed/trailers/#{slug}",
      duration: "PT2M30S"
    )
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
