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
