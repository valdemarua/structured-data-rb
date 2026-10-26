# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Gem skeleton: gemspec, Minitest and RuboCop setup, CI and release workflows.
- `StructuredData::Entity` base class with `properties`, `url_properties`, `date_properties` and `enum` declarations, and light value checks.
- `StructuredData.graph`, `json_ld` and `script_tag`: one `@graph` document, escaped for `<script>` tags.
- `id:` on entities, `StructuredData::Ref` and `entity.ref` for `@id` references. Top-level entities with the same `@id` are written once.
- `StructuredData::Ids` for building `@id` values (`organization`, `website`, `site`, `page`, `entity`).
- `extra:` on entities for Schema.org properties the gem does not model yet.
- Schema.org types: `Thing`, `CreativeWork`, `Organization`, `Person`, `ImageObject`, `Place`, `WebSite`, `WebPage`, `CollectionPage`, `ItemList`, `BreadcrumbList` (with `BreadcrumbList.from`), `ListItem`, `Article`, `NewsArticle`, `Event`, `SportsEvent`, `SportsOrganization`, `SportsTeam`, `StadiumOrArena`, `Movie`, `AggregateRating`.
- `NewsMediaOrganization`, the `Organization` subtype for news publishers.
- `PostalAddress` for `Place.address`, and `QuantitativeValue` with `Person` `height` and `weight`.
- `TVSeries`, `TVSeason` and `TVEpisode`, `VideoObject` (with `MediaObject`, now also the parent of `ImageObject`), `trailer` on `Movie` and the TV types, `content_rating` on `CreativeWork`, and `death_date` on `Person`.
- Optional Rails integration (`require "structured_data/rails"`, Rails 8.1.4+): the `structured_data_tag` view helper.
### Changed

- `json` dependency widened from `~> 3.0` to `>= 2.7, < 4`. The gem only needs `JSON.generate(..., script_safe: true)` (json 2.7+), so it no longer forces apps onto json 3. Output is identical on json 2.7, the newest 2.x and 3.x, which CI now tests.
- The optional Rails integration supports Rails 7.1+ (was 8.1.4+). CI tests Rails 7.1, 7.2 and 8.0 with json 2.x and 8.1 with json 3.x.

