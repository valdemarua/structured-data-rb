# structured-data-rb — v0.1 plan

Status: draft, 2026-10-10. Repository: https://github.com/valdemarua/structured-data-rb

Contents

1. [Goals and non-goals](#1-goals-and-non-goals)
2. [Schema types: implementation order](#2-schema-types-implementation-order)
3. [Lessons from other ecosystems](#3-lessons-from-other-ecosystems)
4. [Architecture and API](#4-architecture-and-api)
5. [Gem engineering practices (2026)](#5-gem-engineering-practices-2026)
6. [Milestones](#6-milestones)
7. [Risks and open questions](#7-risks-and-open-questions)
8. [Sources](#8-sources)

---

## 1. Goals and non-goals

Goal: one small, pure-Ruby gem that turns explicitly mapped domain objects into correct, safe
Schema.org JSON-LD, for any Ruby or Rails app.

**Client-agnostic by design.** The gem never knows about a particular app, domain model,
URL scheme or site. It provides building blocks: entities, validation, `@id` helpers,
graphs and rendering. Clients use them to implement their own mapping. Section 2
only sets the order in which Schema.org types are added. Nothing app-specific appears in
the code, examples, tests or issues.

Core decisions:

- JSON-LD only. No Microdata or RDFa.
- Schema.org is the vocabulary. The gem models a curated subset.
- Pure Ruby core. Rails integration is an optional, thin helper.
- No ActiveRecord introspection. Each app maps its models explicitly.
- Validation lives in the gem. Schema.org validity is separate from Google rich-result rules.
- Deterministic output: always one `@graph` document per call.
- Out of scope: meta tags, OpenGraph, Twitter Cards, runtime schema fetching, full vocabulary,
  code generation in v0.1.

## 2. Schema types: implementation order

Types are added in this order. Each property list follows Schema.org, and Google's
documented recommendations where Google has a matching feature.

**P0, shipped in v0.1**

1. `Organization` and `WebSite`: site-wide nodes, usually referenced by `@id`.
   `NewsMediaOrganization` is the `Organization` subtype for news publishers.
2. `Article` and `NewsArticle`, with `Person` / `Organization` as `author` and `publisher`,
   `ImageObject`, and `about` / `mentions` references to other entities. Article is a
   Google rich-result feature.
3. `BreadcrumbList` + `ListItem`. Also a Google rich-result feature. Includes the
   `BreadcrumbList.from` shortcut for `[name, url]` pairs.
4. `SportsOrganization` (a league) and `SportsTeam`: `sport`, `logo`, `foundingDate`,
   `memberOf`, `athlete`, `coach`.
5. `Person` for athletes and authors: `name`, `alternateName`, `image`, `birthDate`,
   `nationality`, `memberOf`.
6. `SportsEvent` for matches: `homeTeam`, `awayTeam`, `competitor`, `startDate`, `endDate`,
   `eventStatus`, `location` (`Place` / `StadiumOrArena`), `sport`, `superEvent`.
7. `SportsEvent` with `subEvent` for multi-session events, such as a race weekend with
   practice, qualifying and race.
8. `Movie` + `AggregateRating`.

**P1, in v0.1 if time allows, otherwise v0.2**

- `WebPage` / `CollectionPage`, linked to `WebSite` with `isPartOf`.
- `ItemList`, for lists of articles or events.

**Not planned**

- Match scores. Schema.org has no score property on `SportsEvent`, and the gem will not
  invent one.
- `ProfilePage`. Google intends it for creator profiles, so athlete pages should use
  `Person` instead.
- Standings or league tables. There is no suitable Schema.org type.

**v0.1 entity list:** `Thing` (base), `CreativeWork`, `Organization`,
`NewsMediaOrganization`, `SportsOrganization`, `SportsTeam`, `Person`, `ImageObject`,
`Place`, `StadiumOrArena`, `WebSite`, `WebPage`, `CollectionPage`, `ItemList`,
`BreadcrumbList`, `ListItem`, `Article`, `NewsArticle`, `Event`, `SportsEvent`, `Movie`,
`AggregateRating`. Each is a short property list; intermediate Schema.org types
(`Intangible`, `MediaObject`, `CivicStructure`) are skipped where nothing needs them.

## 3. Lessons from other ecosystems

| Library | Ecosystem | Approach | What we take | What we skip |
|---|---|---|---|---|
| [schema-dts](https://github.com/google/schema-dts) (Google, ~1.2k★) | TypeScript | Types generated from the Schema.org ontology. `WithContext<T>`, `Graph`, `@id` references. | `@context` only on the root. An explicit `@id` reference type. A generator as a later step, pinned to a vocabulary version. Its README tells you to escape `<`, `>`, `&` inside `<script>`. | Full-vocabulary types (no runtime value, huge surface). |
| [@unhead/schema-org](https://github.com/unjs/unhead/tree/main/packages/schema-org) | Node / Vue / React | `define*` helpers for a practical subset. Nodes link automatically by `@id`. Framework-agnostic core with framework adapters. Extra properties pass through. | The scope: a curated subset focused on what search engines use. The core/adapter split (ours: pure core + Railtie). An escape hatch for extra properties. Stable `@id` conventions for site-wide nodes. | Implicit global "site config" (we pass context explicitly). Reactivity. |
| [spatie/schema-org](https://github.com/spatie/schema-org) (~1.5k★) | PHP | Fluent builder generated from Schema.org. `Graph` with named node identifiers. `MultiTypedEntity`. `if()` for conditional properties. | Multi-type support later (e.g. `["Movie", "CreativeWork"]` is rare, so v0.2). | Fluent mutable builders: Ruby keyword arguments + `nil` omission already solve the "conditional chaining" problem. |
| [Schema.NET](https://github.com/RehanSaeed/Schema.NET) (~700★) | .NET | Generated, strongly typed classes. `OneOrMany<T>` and `Values<T1,T2>` for union and array properties. | **Every property accepts one value or an array.** | Codegen of the whole vocabulary. Per-property union types (runtime checks stay light). |
| [teseo/schemaorg](https://pkg.go.dev/github.com/indaco/teseo/schemaorg) | Go | Plain structs, `omitempty`, constructor per type. Renders to a `templ` component or `template.HTML`. `Validate()` returns *warnings* for missing recommended fields. | `nil` → omitted (Go's `omitempty`). The renderer is separate from the data. **Profiles return warnings and do not raise**: that is how we will do Google checks later. | Positional constructors (fragile; Ruby has keyword arguments). |
| [schema_dot_org](https://github.com/public-law/schema-dot-org) (~80★, 2.5.x) | Ruby | Declarative `validated_attr`, fails at construction, about 20 types. | Fail fast at construction. Reject unknown attributes. Readable class bodies. | ActiveModel/ActiveSupport dependency (via `validated_object`). Rendering through `to_s` (implicit, surprising). |

Takeaways that shape the design:

1. **Keep the type set curated and hand-written.** Every mature full-vocabulary library is
   generated. That only pays off once the property-declaration DSL is stable, so it waits
   until after v0.1. Keep the DSL simple enough that a generator could emit it later.
2. **`@id` and `@graph` are the real power feature.** unhead and schema-dts both centre on
   linking nodes, not nesting copies of them. Site-wide `Organization` / `WebSite` nodes
   should be declared once per page and referenced everywhere else.
3. **Safe embedding is part of the library's job.** Every ecosystem has had
   `</script>`-injection bugs in hand-rolled JSON-LD. The library must escape by default.
4. **Keep runtime checks light.** Neither unhead nor schema-dts validates Schema.org at
   runtime (unhead: helpers "do not perform runtime Schema.org or Google validation").
   We catch the mistakes that are cheap to catch and easy to make: unknown properties,
   relative URLs, unknown enum values. Search-engine recommendations (Google) become
   warnings in an optional profile later.
5. **Output what the client wrote.** Node packages emit objects as written: key order,
   single values and arrays are left alone. No hidden reordering or normalisation.

## 4. Architecture and API

### Layers

```
StructuredData::Entity subclasses   (type name + list of supported properties)
        │  light checks at construction
        ▼
StructuredData.json_ld(*entities)   (one @graph document, @id de-duplication,
StructuredData.script_tag(*entities)  JSON.generate + script-safe escaping)
        ▼
StructuredData::Rails::Helper       (optional; html_safe <script> tag in views)

StructuredData::Profiles::Google    (v0.2; warnings only, never mutates output)
```

### Entity definitions

```ruby
module StructuredData
  # https://schema.org/SportsTeam
  class SportsTeam < SportsOrganization   # inheritance mirrors Schema.org where useful
    properties :athlete, :coach
  end

  # https://schema.org/Event
  class Event < Thing
    properties :start_date, :end_date, :location, :organizer, :sub_event, :super_event
    enum :event_status, %w[EventScheduled EventCancelled EventPostponed EventRescheduled EventMovedOnline]
  end

  # https://schema.org/Thing
  class Thing < Entity
    properties :name, :alternate_name, :description, :same_as
    url_properties :url, :image          # strings must be absolute http(s) URLs
  end
end
```

The Schema.org type name is the class name. A class declares only its own properties and
inherits the rest.

Rules:

- **Keyword-only constructor.** Unknown keywords raise `StructuredData::UnknownPropertyError`.
- **Key order and values are kept as passed.** Output is `@type`, `@id`, then properties in
  the order the client passed them. A single value stays single and an array stays an
  array.
- **`nil` and empty arrays are omitted.** This makes conditional properties free:
  `image: post.image_url`.
- **Name mapping:** `snake_case` → `lowerCamelCase` (`date_published` → `datePublished`).
- **Values:** `String`, `Numeric`, `true` / `false`, any object that responds to `iso8601`
  (`Time`, `Date`, `DateTime` or a framework time class; written with its own offset, and the
  gem never converts time zones), an entity, a `Ref`, or an array of these. Anything else
  raises `ValidationError`. Strings are kept as is, so partial dates like `"1947"` work.
- **URL properties** (`url`, `image`, `logo`, `item`, `same_as`, `main_entity_of_page`, …):
  when given as a string, it must be an absolute `http(s)` URL.
- **Date properties** (`date_published`, `start_date`, `birth_date`, `founding_date`, …),
  declared with `date_properties`: a string must be ISO 8601, full or partial (`1947`,
  `2026-09`, `2026-09-25`, `2026-09-25T08:33:00+03:00`).
- **Enums** take the Schema.org member name and are written as the full URL:
  `event_status: "EventScheduled"` → `"https://schema.org/EventScheduled"`. Unknown names
  raise.
- **No checks on which entity goes where.** As in unhead and schema-dts at runtime, putting
  a `Person` into `home_team` is not caught. Generating runtime rules from the vocabulary
  was considered and rejected as too much machinery for a builder. Clients check meaning
  with the Schema.org validator, Google's Rich Results Test and Search Console (see
  README). The vocabulary test (below) keeps our own declarations correct.
- **Errors name the property,** e.g. `Person url: expected an absolute http(s) URL, got
  "/people/x"`. One base class, `StructuredData::Error < StandardError`, with
  `ValidationError` and `UnknownPropertyError` subclasses.
- **Entities are immutable** (frozen after construction).
- **`id:`** sets `@id`. `StructuredData::Ref.new("https://example.com/#organization")`
  refers to a node without repeating it, and `entity.ref` builds a `Ref` from an entity
  that has an `id:` (it raises if there is none).
- **`@id` values are chosen by the client.** The gem validates only "absolute URI". To
  make the common convention easy, it ships `StructuredData::Ids`, a plain value object with
  no global state:
  `Ids.new(base_url)` has `#organization` (`<base>/#organization`), `#website`,
  `#site(name)` (`<base>/#<name>`), `#page(url_or_path)` (the absolute URL, fragment
  stripped) and `#entity(url_or_path, kind)` (`<url>#<kind>`). Relative paths resolve
  against `base_url`. Using it is optional.
- **Escape hatch:** `extra: { "sameAs" => [...] }` is merged verbatim after the declared
  properties. It may not override `@type`, `@id` or declared keys. This keeps clients
  unblocked between releases (lesson from unhead).

### Serialization

- `entity.to_h` returns the node as a string-keyed Hash, without `@context`.
- `StructuredData.graph(*entities)` returns `{"@context" => "https://schema.org",
  "@graph" => [...]}`. There is always one `@graph` document, even for a single entity,
  as in unhead. If two top-level entities share an `@id`, only the first is kept.
- `StructuredData.json_ld(*entities)` returns that document as a JSON string via
  `JSON.generate(doc, script_safe: true)`. `script_safe` escapes `/` and U+2028/2029. We
  then also replace `<` `>` `&` with `<` `>` `&`, the same escaping schema-dts
  and `ERB::Util.json_escape` use, so it is safe inside `<script>` with any template
  engine. Non-ASCII text stays as UTF-8 (no `ascii_only`).
- `StructuredData.script_tag(*entities)` returns the full
  `<script type="application/ld+json">…</script>` string. It is pure Ruby and not
  `html_safe` (core knows nothing about Rails).
- No global configuration. This matches json 3, which dropped mutable global defaults.
  Site-wide values such as the base URL and `inLanguage` are passed explicitly, e.g. through
  an `Ids` instance the client creates.

### Vocabulary test

`rake vocab` downloads a pinned Schema.org release (`Vocabulary::VERSION`, currently 30.1)
into `tmp/` and checks every entity class: the type exists, each property exists and is
allowed on the type, date properties have a date range, and enum members are valid. It also
checks the golden fixtures, including which entity types appear under which properties.
It runs in CI. The checker lives in `test/support/vocabulary.rb` and is not shipped. This replaces generated types: our declarations stay hand-written, but
cannot drift from Schema.org.

### Rails integration (`lib/structured_data/rails/*`, opt-in)

- Load it with `require "structured_data/rails"` (or have Bundler `require:` it). It is
  not loaded by `require "structured_data"`.
- The Railtie includes a helper into `ActionView`:
  `structured_data_tag(*entities)` → one entity renders as a document, several render as a
  `@graph`. It returns an `html_safe` string built from the core `script_tag`.
- The gem has no runtime dependency on `railties`. Rails 8.1.4+ is required, because earlier
  versions are incompatible with json 3. CI tests against Rails 8.1.

### Client mapping (documented pattern, not gem code)

```ruby
# app/structured_data/article_schema.rb (in the client app)
class ArticleSchema
  IDS = StructuredData::Ids.new("https://example.com")

  def initialize(article, view) = (@article, @view = article, view)

  def call
    url = @view.article_url(@article)
    StructuredData::NewsArticle.new(
      id:             IDS.entity(url, :article),
      headline:       @article.title,
      url:            url,
      date_published: @article.published_at,
      date_modified:  @article.updated_at,
      image:          @article.image_url,
      publisher:      StructuredData::Ref.new(IDS.organization),
      about:          @article.tags.map { StructuredData::Ref.new(IDS.entity(@view.tag_url(it), :topic)) }
    )
  end
end
```

## 5. Gem engineering practices (2026)

### Platform and dependencies

| Item | Decision | Why |
|---|---|---|
| Ruby | `required_ruby_version >= 3.3` | 3.2 reached EOL on 2026-03-31. 3.3 is security-only until 2027-03. 3.4 and 4.0 are current. |
| Runtime deps | `json ~> 3.0`. Nothing else. | json 3 is safe by default, has no mutable global options (Ractor-safe), rejects unknown options and duplicate keys, and supports `script_safe`. One major version means one CI configuration. |
| Stdlib used | `json`, `date`, `time` | No ActiveSupport, no Zeitwerk (plain `require_relative`; about 25 files). |
| Dev deps | `minitest ~> 6.0`, `rake`, `rubocop` + `rubocop-minitest` + `rubocop-performance` | Declared in the `Gemfile`, not the gemspec (current Bundler convention). |
| Rails (test only) | `gemfiles/rails_8_1.gemfile` | Rails 8.1.4+ only: ActiveSupport 8.0 passes options that json 3 rejects, so `to_json` fails, and ActiveSupport 8.1.0–8.1.3 passes `JSON.parse` options positionally, so `ActiveSupport::JSON.decode` fails. Use the `BUNDLE_GEMFILE` env in CI. No Appraisal needed. |

### Repository layout

```
structured-data-rb/
├── lib/structured_data.rb
├── lib/structured_data/{version,error,entity,ref,ids,document}.rb
├── lib/structured_data/entities/*.rb
├── lib/structured_data/rails.rb, rails/{railtie,helper}.rb
├── sig/structured_data.rbs            # public API signatures (P1)
├── test/test_helper.rb
├── test/structured_data/**/*_test.rb
├── test/fixtures/*.json               # golden JSON-LD outputs
├── test/rails/*_test.rb               # run only with a Rails gemfile
├── test/dummy/                        # minimal Rails app for end-to-end checks
├── gemfiles/rails_8_1.gemfile
├── docs/PLAN.md
├── README.md, CHANGELOG.md, LICENSE
├── AGENTS.md, CLAUDE.md
├── structured-data-rb.gemspec
└── .github/workflows/{ci,release}.yml, .github/dependabot.yml
```

Gem name: `structured-data-rb` (free on rubygems.org as of 2026-10-10). Require path:
`structured_data`. Namespace: `StructuredData`. Gemspec `files` is an explicit allow-list
(`lib/**`, `sig/**`, `README.md`, `LICENSE`, `CHANGELOG.md`). Tests and docs are not shipped.

### Tests (Minitest)

- Use the `Minitest::Test` style, one file per entity plus core files. Plain `assert_equal`
  on Hashes; no mocks needed.
- **Golden fixtures:** for each realistic example (news article, sports team page, match,
  multi-session race weekend, movie), `to_h` is compared with
  `test/fixtures/<name>.json`. Regenerate them with `UPDATE_FIXTURES=1 rake test` and
  review the diff.
- **Escaping tests:** `</script>`, `<!--`, `&`, U+2028, non-ASCII text, emoji.
- **Validation tests:** every error message is asserted.
- **Vocabulary test:** `rake vocab` checks declarations and fixtures against the pinned
  Schema.org release (see section 4).
- **Rails helper tests:** use `ActionView::TestCase` under `test/rails`, skipped when
  Rails isn't loaded.
- **External validation (manual, before each release):** paste the fixtures into
  validator.schema.org and Google's Rich Results Test. Record the date in `CHANGELOG.md`.
- Coverage: no extra dependency. Optionally use Ruby's built-in `Coverage` in
  `test_helper.rb`, behind the env var `COVERAGE=1`.

### CI (GitHub Actions)

`ci.yml` runs on push and pull requests:

- `lint`: `bundle exec rubocop` on Ruby 4.0.
- `test`: matrix of Ruby `3.3`, `3.4`, `4.0`, plus `head` (allowed to fail).
  Runs `bundle exec rake test`.
- `rails`: Ruby 4.0 with the `rails_8_1` gemfile. Runs `bundle exec rake test:rails`.
- `build`: `gem build` and check the file list, so the packaged gem contains no test files.
- Set `permissions: contents: read` and pin actions by commit SHA. Dependabot handles
  `github-actions` and `bundler` weekly. `ruby/setup-ruby` with `bundler-cache: true`.

### Releases and publishing

- Version in `lib/structured_data/version.rb`, following SemVer. `0.x` minors may break
  the API; this is called out in the README.
- `CHANGELOG.md` in Keep a Changelog format, with an `Unreleased` section updated in
  every PR.
- Releasing:
  1. Open a PR that bumps the version and moves `Unreleased` → `## [0.1.0] - date`.
  2. Merge it.
  3. `git tag v0.1.0 && git push --tags`.
  4. `release.yml` runs on `v*` tags: tests, then `rubygems/release-gem@v1`.
- **Trusted Publishing (OIDC)** on rubygems.org. There is no API key in secrets.
  `release-gem` also pushes Sigstore attestations. The workflow needs
  `id-token: write` and `contents: write`, plus a protected `release` environment.
  The first push of a brand-new gem can use a *pending* trusted publisher, so no manual
  first push is needed.
- Gemspec metadata: `rubygems_mfa_required = "true"`, `source_code_uri`,
  `changelog_uri`, `bug_tracker_uri`, `documentation_uri`.
- Create a GitHub Release from the tag with the CHANGELOG section as notes.

### Documentation

- A single English `README.md` is the user documentation.
- YARD-style comments on public classes and methods only. rubydoc.info renders them
  automatically.
- No docs site for now. Revisit if the README outgrows one page (more types, profiles,
  guides).
- `docs/` holds design notes (`PLAN.md`), not user docs.
- Per-entity docs come from the code: each entity file starts with a comment linking its
  `https://schema.org/<Type>` page.

## 6. Milestones

Each step is one PR with tests, and each keeps `master` releasable.

| # | Step | Done when |
|---|---|---|
| 0 | Repo skeleton: gemspec, Gemfile, Rakefile, rubocop, CI, CHANGELOG | CI is green on an empty test suite. `gem build` works. |
| 1 | Lock the API with 3 golden fixtures written first (news article, sports team, match between two teams) | Fixtures reviewed against validator.schema.org. |
| 2 | Core: `Entity`, `properties` / `url_properties` / `date_properties` / `enum`, value conversion, `to_h`, `StructuredData.graph` / `json_ld` / `script_tag` + escaping | Escaping and value tests pass. |
| 3 | Nested entities, arrays, `Ref`, `id:`, `#ref`, `Ids`, `@id` de-duplication in the document | Fixtures with refs pass. |
| 4 | Errors (unknown property, value kind, URL, date, enum), `extra:`, `rake vocab` in CI | Every error is tested. Vocabulary check is green. |
| 5 | Shared entities: Thing, Organization, Person, ImageObject, Place, WebSite, WebPage, BreadcrumbList/ListItem, plus `BreadcrumbList.from([[name, url], ...])` (auto positions, last item may omit the URL) | Fixtures pass. |
| 6 | NewsArticle/Article, SportsOrganization, SportsTeam, StadiumOrArena, SportsEvent (+ `subEvent`), `event_status` enum | All sports fixtures pass. |
| 7 | Movie + AggregateRating | Movie fixture passes. |
| 8 | Optional Rails Railtie + `structured_data_tag` | The Rails 8.1 CI job is green. |
| 9 | End-to-end check in a sample Rails app (`test/dummy`): article, breadcrumbs, team, person, event pages | Rich Results Test passes for article and breadcrumb. No warnings we can't explain. |
| 10 | Trial in internal projects, installed from GitHub (`github: "valdemarua/structured-data-rb"`) | The gem covers real pages without workarounds. Rich Results Test and Search Console show no unexpected issues. |
| 11 | Release 0.1.0 through trusted publishing | The gem is installable. Attestation is visible on rubygems.org. |
| 12 | Retro: Google profile (warnings), RBS, codegen decision | Issues filed for v0.2. |

## 7. Risks and open questions

- **Scores and live data.** Schema.org has no score property. Docs and examples must not
  emulate one through `extra:`.
- **Event rich results.** Google's Event feature targets attendable events. Sports pages
  may get entity understanding but no visual rich result. Article and Breadcrumb are the
  measurable wins. Set expectations accordingly.
- **Decided: error messages are English only,** like all names and examples in the docs.
- **Decided: clients choose `@id` values; the gem provides helpers.** That means `id:`, `Ref`,
  `#ref`, `@id` de-duplication and the optional `Ids` builder for the common convention
  (`<base>/#organization`, `<base>/#website`, the canonical URL for pages,
  `<canonical>#<kind>` for a page's main entity).

## 8. Sources

- json 3.0 changelog: https://github.com/ruby/json/blob/master/CHANGES.md
- Ruby maintenance branches: https://www.ruby-lang.org/en/downloads/branches/ and https://endoflife.date/ruby
- RubyGems trusted publishing: https://guides.rubygems.org/trusted-publishing/ and https://blog.rubygems.org/2023/12/14/trusted-publishing.html
- Google: simplifying search results (2025): https://developers.google.com/search/blog/2025/06/simplifying-search-results
- Google search gallery: https://developers.google.com/search/docs/appearance/structured-data/search-gallery
- schema-dts: https://github.com/google/schema-dts
- @unhead/schema-org: https://github.com/unjs/unhead/tree/main/packages/schema-org
- spatie/schema-org: https://github.com/spatie/schema-org
- Schema.NET: https://github.com/RehanSaeed/Schema.NET
- teseo/schemaorg (Go): https://pkg.go.dev/github.com/indaco/teseo/schemaorg
- schema_dot_org (Ruby): https://github.com/public-law/schema-dot-org
- Schema.org releases (v30.1, 2026-09-15): https://github.com/schemaorg/schemaorg/releases
