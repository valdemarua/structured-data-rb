# Agent Instructions

`structured-data-rb` is a small pure-Ruby gem that builds Schema.org JSON-LD from explicitly mapped objects.
Full design and roadmap: `docs/PLAN.md`. Read it before changing the public API.

## Architecture

- `lib/structured_data/entity.rb`, `property.rb`, `types.rb`: the property DSL. Values are type-checked when an entity is constructed.
- `lib/structured_data/entities/*.rb`: one file per Schema.org type. Each is mostly a `schema_type` and a list of `property` declarations.
- `lib/structured_data/ref.rb`, `ids.rb`, `graph.rb`: `@id` references, the optional `Ids` builder for common `@id` values, and `@graph` documents.
- `lib/structured_data/serializer.rb`: `to_h`, `to_json_ld` and `script_tag`. This is the only place JSON is generated.
- `lib/structured_data/rails/*`: optional Railtie and view helper. Loaded only through `require "structured_data/rails"`.

## Rules

- Core must not require Rails, ActiveSupport or ActiveRecord. The only runtime dependency is `json ~> 3.0`. Ask before adding another.
- Support Ruby >= 3.3. Load files with `require_relative`. Do not use Zeitwerk.
- JSON-LD only. Add Schema.org types and properties deliberately, following the order in `docs/PLAN.md`; never model the full vocabulary. Each entity file starts with a comment linking its `https://schema.org/<Type>` page.
- Output is deterministic. Key order is `@context` (root only), `@type`, `@id`, then properties in declaration order. `nil` values and empty arrays are omitted.
- Escaping is mandatory. JSON goes through `JSON.generate(..., script_safe: true)` and then `<`, `>` and `&` are replaced with `\u003c`, `\u003e` and `\u0026`. Never bypass the serializer.
- Schema.org type errors raise `StructuredData::ValidationError` with a property path. Google recommendations are warnings in a profile and never raise.
- No global mutable configuration.
- The gem is client-agnostic: it provides building blocks and helpers, and mapping a client's models to entities is the client's job. Never reference specific client apps or sites in code, tests, docs or issues.
- All names and examples in code, tests and docs are in English and generic (`example.com`, "Jane Doe").

## Workflow notes

- IMPORTANT: Never mention AI assistants or agents (Claude, Claude Code, Codex, Copilot, etc.) in commit messages, including `Co-Authored-By` trailers
- IMPORTANT: Never include "Test plan" sections in PR descriptions
- The standard location for documentation and specs is `docs/`

## Tools

- Setup: `bundle install`
- Tests (Minitest): `bundle exec rake test`. Rails helper tests: `BUNDLE_GEMFILE=gemfiles/rails_8_1.gemfile bundle exec rake test:rails`.
- Golden fixtures live in `test/fixtures/*.json`. Regenerate them with `UPDATE_FIXTURES=1 bundle exec rake test` and review the diff.
- Lint: `bundle exec rubocop`
- Every user-visible change adds a line under `Unreleased` in `CHANGELOG.md`.
- Releases: bump `lib/structured_data/version.rb`, move the CHANGELOG entries, then tag `vX.Y.Z`. CI publishes through RubyGems trusted publishing. Never run `gem push` locally.
