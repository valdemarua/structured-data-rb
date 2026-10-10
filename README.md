# structured-data-rb

Build Schema.org JSON-LD in plain Ruby. You get validated entities, deterministic output and
safe `<script>` embedding. A small optional Rails helper is included.

> **Status: pre-release (0.x).** The API described here is the v0.1 target and may change
> before 1.0. See [docs/PLAN.md](docs/PLAN.md).

```ruby
article = StructuredData::NewsArticle.new(
  headline: "City council approves new bike lanes",
  url: "https://example.com/news/bike-lanes",
  date_published: Time.new(2026, 9, 25, 8, 33, 0, "+03:00"),
  in_language: "en",
  publisher: StructuredData::Organization.new(name: "Example News", url: "https://example.com/")
)

StructuredData.json_ld(article)
```

```json
{"@context":"https:\/\/schema.org","@graph":[{"@type":"NewsArticle","headline":"City council approves new bike lanes","url":"https:\/\/example.com\/news\/bike-lanes","datePublished":"2026-09-25T08:33:00+03:00","inLanguage":"en","publisher":{"@type":"Organization","name":"Example News","url":"https:\/\/example.com\/"}}]}
```

Forward slashes are escaped (`\/`) so the output is safe inside a `<script>` tag. JSON
parsers read it as an ordinary `/`.

## Why

- **JSON-LD only.** It is the format search engines recommend, and the only one this gem
  produces.
- **Almost no dependencies.** The only runtime dependency is Ruby's own
  [`json`](https://github.com/ruby/json) library (version 3). No Rails, ActiveSupport or
  ActiveRecord is needed.
- **Fails early.** Unknown properties, relative URLs and unknown enum values raise errors
  that name the property.
- **Safe to embed.** Output is escaped for `<script>` tags. Non-ASCII text (Cyrillic, CJK,
  emoji) stays readable.
- **Works with any app.** The gem knows nothing about your models, routes or domain. You
  map your data to Schema.org, and the gem provides the building blocks.

## Installation

The gem is not on rubygems.org yet. Until the first release, install it from GitHub:

```ruby
# Gemfile
gem "structured-data-rb", github: "valdemarua/structured-data-rb"
```

Requires Ruby 3.3+ and `json` 3.x. The optional Rails integration requires Rails 8.1+.

## Usage

### Entities and documents

Entities are plain Ruby objects. Pass Schema.org properties as `snake_case` keywords:

```ruby
require "structured_data"

team = StructuredData::SportsTeam.new(
  name: "Riverside Rovers",
  url: "https://example.com/teams/riverside-rovers",
  logo: "https://example.com/images/rovers.png",
  sport: "Football",
  founding_date: "1947"
)

team.to_h                       # => {"@type" => "SportsTeam", "name" => "Riverside Rovers", ...}
StructuredData.json_ld(team)    # => '{"@context":"https:\/\/schema.org","@graph":[{...}]}'
```

`StructuredData.json_ld` always returns one `@graph` document, for one entity or many.
Keys come out in the order you pass them, and values come out as given: a single value
stays a single value, and an array stays an array.

- Dates and times are written with their own `iso8601` method: a `Time` keeps its offset,
  and a `Date` becomes `YYYY-MM-DD`. The gem never changes time zones, so convert a time
  to the zone you want before passing it. Strings are kept as they are, so partial dates
  such as `"1947"` work.
- Enum values use their Schema.org name: `event_status: "EventScheduled"` is written as
  `"https://schema.org/EventScheduled"`.

Properties set to `nil` are left out, so optional data needs no conditionals:

```ruby
StructuredData::Person.new(name: author.name, image: author.avatar_url) # avatar may be nil
```

### Linking entities with `@id`

Give a shared entity an `id:` once. Everywhere else, point to it with `#ref` instead of
repeating it:

```ruby
organization = StructuredData::Organization.new(
  id: "https://example.com/#organization",
  name: "Example News",
  url: "https://example.com/"
)

team = StructuredData::SportsTeam.new(
  id: "https://example.com/teams/riverside-rovers#team",
  name: "Riverside Rovers",
  url: "https://example.com/teams/riverside-rovers"
)

article = StructuredData::NewsArticle.new(
  headline: "Rovers sign a new head coach",
  publisher: organization.ref,   # => {"@id": "https://example.com/#organization"}
  about: team.ref
)

StructuredData.json_ld(organization, team, article)
# => {"@context":"https://schema.org","@graph":[{...Organization...},{...SportsTeam...},{...NewsArticle...}]}
```

If you only have the ID string, use `StructuredData::Ref.new(id)`. If the same `@id` is
passed twice, the document keeps only the first node, so each entity is described once.

#### Building `@id` values

`@id` is a JSON-LD feature. It is a global identifier, not a link that has to open in a
browser. Search engines treat every node with the same `@id` as the same thing, across
all pages of your site. Keep IDs stable: if an ID changes, search engines see a new
entity.

`StructuredData::Ids` builds IDs with a common convention, so you don't assemble strings
by hand:

```ruby
ids = StructuredData::Ids.new("https://example.com")

ids.organization                                # => "https://example.com/#organization"
ids.website                                     # => "https://example.com/#website"
ids.site(:logo)                                 # => "https://example.com/#logo"
ids.page("/teams/riverside-rovers")             # => "https://example.com/teams/riverside-rovers"
ids.entity("/teams/riverside-rovers", :team)    # => "https://example.com/teams/riverside-rovers#team"
```

`Ids` is a plain object with no global state. Create one per site, or per request for
multi-site apps. Using it is optional: any absolute URI works as an `id:`.

### Rendering

Without Rails:

```ruby
StructuredData.script_tag(organization, team, article)
# => "<script type=\"application/ld+json\">{...}</script>"
```

With Rails (8.1+), require the optional integration:

```ruby
# Gemfile
gem "structured-data-rb", require: ["structured_data", "structured_data/rails"]
```

```erb
<%# takes one or more entities, like StructuredData.json_ld %>
<%= structured_data_tag(ArticleSchema.new(@article, self).call, BreadcrumbsSchema.new(@article, self).call) %>
```

### Mapping your models

Keep mapping code in your app, for example in small presenter objects:

```ruby
# app/structured_data/article_schema.rb
class ArticleSchema
  IDS = StructuredData::Ids.new("https://example.com")

  def initialize(article, view)
    @article = article
    @view = view
  end

  def call
    StructuredData::NewsArticle.new(
      id: IDS.entity(@view.article_url(@article), :article),
      headline: @article.title,
      url: @view.article_url(@article),
      date_published: @article.published_at,
      date_modified: @article.updated_at,
      publisher: StructuredData::Ref.new(IDS.organization)
    )
  end
end
```

### Breadcrumbs

Build a `BreadcrumbList` from `[name, url]` pairs. Positions are numbered for you, and the
current page can be listed without a URL:

```ruby
StructuredData::BreadcrumbList.from([
  ["Home", "https://example.com/"],
  ["Teams", "https://example.com/teams"],
  ["Riverside Rovers"]                     # current page
])
```

This returns an ordinary `BreadcrumbList`, so `id:` and validation work as usual.
If you need more control over an item, build it with `StructuredData::ListItem` directly.

### Errors

```ruby
StructuredData::Person.new(name: "Jane Doe", url: "/people/jane-doe")
# => StructuredData::ValidationError: Person url: expected an absolute http(s) URL, got "/people/jane-doe"

StructuredData::Person.new(name: "Jane Doe", team: "Rovers")
# => StructuredData::UnknownPropertyError: Person does not support property :team
```

If you need a Schema.org property the gem does not model yet, pass it through `extra:`:

```ruby
StructuredData::Person.new(name: "Jane Doe", extra: { "knowsLanguage" => ["en", "es"] })
```

## Supported types (v0.1)

| Group | Types |
|---|---|
| Core | `Thing`, `CreativeWork`, `Organization`, `Person`, `ImageObject`, `Place` |
| Site | `WebSite`, `WebPage`, `CollectionPage` |
| Lists | `ItemList`, `BreadcrumbList`, `ListItem` |
| Content | `Article`, `NewsArticle` |
| Events | `Event`, `SportsEvent` |
| Sports | `SportsOrganization`, `SportsTeam`, `StadiumOrArena` |
| Media (planned for 0.1) | `Movie`, `AggregateRating` |

Each type supports the Schema.org properties listed in its file in
[`lib/structured_data/entities`](lib/structured_data/entities), plus everything it inherits.

If a type you need is missing, use `extra:` for now and open an issue.

## Scope

**In scope:** Schema.org JSON-LD entities, light validation, `@graph` documents, `@id`
references and helpers, safe rendering.

**Out of scope:** Microdata, RDFa, OpenGraph, Twitter Cards, meta tags, automatic
ActiveRecord mapping, and the full Schema.org vocabulary.

## Checking your output

The gem catches cheap, obvious mistakes when an entity is built: unknown properties,
relative URLs, malformed dates and unknown enum values. It does not check whether, say,
a `Person` belongs in `home_team`, or whether Google will show a rich result. Use these
tools for that:

- [Google's Rich Results Test](https://search.google.com/test/rich-results): which rich
  results a page qualifies for, with errors and warnings.
- [Schema.org validator](https://validator.schema.org/): types and properties against the
  full vocabulary.
- [Google Search Console](https://search.google.com/search-console) → Enhancements:
  structured-data issues across all indexed pages, including ones caused by real data.
- Your own tests: assert the output of `StructuredData.json_ld(...)` for each page type.

Check each page type once in the validators when you add it, then let Search Console
monitor production.

## Development

```sh
bundle install
bundle exec rake test       # Minitest
bundle exec rubocop         # lint
```

Rails helper tests:

```sh
BUNDLE_GEMFILE=gemfiles/rails_8_1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_8_1.gemfile bundle exec rake test:rails
```

Releases are published from CI with RubyGems trusted publishing when a `vX.Y.Z` tag is
pushed. See [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE)
