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
- Optional Rails integration (`require "structured_data/rails"`, Rails 8.1+): the `structured_data_tag` view helper.
