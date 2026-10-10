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
- Deterministic `to_h` / `to_json_ld`. Supports a single root entity and `@graph`.
- Out of scope: meta tags, OpenGraph, Twitter Cards, runtime schema fetching, full vocabulary,
  code generation in v0.1.

## 2. Schema types: implementation order

Types are added in this order. Each property list follows Schema.org, and Google's
documented recommendations where Google has a matching feature.

**P0, shipped in v0.1**

1. `Organization` and `WebSite`: site-wide nodes, usually referenced by `@id`.
2. `Article` and `NewsArticle`, with `Person` / `Organization` as `author` and `publisher`,
   `ImageObject`, and `about` / `mentions` references to other entities. Article is a
   Google rich-result feature.
3. `BreadcrumbList` + `ListItem`. Also a Google rich-result feature.
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

**v0.1 entity list:** `Thing` (base), `Organization`, `SportsOrganization`, `SportsTeam`,
`Person`, `ImageObject`, `Place`, `StadiumOrArena`, `WebSite`, `WebPage`, `Article`,
`NewsArticle`, `SportsEvent`, `BreadcrumbList`, `ListItem`, `Movie`, `AggregateRating`.
That is 17 small classes, each mostly a property list.

## 3. Lessons from other ecosystems

| Library | Ecosystem | Approach | What we take | What we skip |
|---|---|---|---|---|
| [schema-dts](https://github.com/google/schema-dts) (Google, ~1.2k★) | TypeScript | Types generated from the Schema.org ontology. `WithContext<T>`, `Graph`, `@id` references. | `@context` only on the root. An explicit `@id` reference type. A generator as a later step, pinned to a vocabulary version. Its README tells you to escape `<`, `>`, `&` inside `<script>`. | Full-vocabulary types (no runtime value, huge surface). |
| [@unhead/schema-org](https://github.com/unjs/unhead/tree/main/packages/schema-org) | Node / Vue / React | `define*` helpers for a practical subset. Nodes link automatically by `@id`. Framework-agnostic core with framework adapters. Extra properties pass through. | The scope: a curated subset focused on what search engines use. The core/adapter split (ours: pure core + Railtie). An escape hatch for extra properties. Stable `@id` conventions for site-wide nodes. | Implicit global "site config" (we pass context explicitly). Reactivity. |
| [spatie/schema-org](https://github.com/spatie/schema-org) (~1.5k★) | PHP | Fluent builder generated from Schema.org. `Graph` with named node identifiers. `MultiTypedEntity`. `if()` for conditional properties. | `Graph` as a first-class object. Multi-type support later (e.g. `["Movie", "CreativeWork"]` is rare, so v0.2). | Fluent mutable builders: Ruby keyword arguments + `nil` omission already solve the "conditional chaining" problem. |
| [Schema.NET](https://github.com/RehanSaeed/Schema.NET) (~700★) | .NET | Generated, strongly typed classes. `OneOrMany<T>` and `Values<T1,T2>` for union and array properties. | **Every property accepts one value or an array.** Union types per property (`author: Person \| Organization`). Serialize a single-element array as a scalar. | Codegen of the whole vocabulary. |
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
4. **Separate correctness levels.** Schema.org type correctness raises errors. Search-engine
   recommendations (Google) produce warnings in an optional profile.

## 4. Architecture and API

### Layers

```
StructuredData::Entity subclasses  (vocabulary: type name + property declarations)
        │  property DSL + type coercion/validation at construction
        ▼
StructuredData::Graph               (optional; several nodes, @id linking)
        ▼
StructuredData::Serializer          (to_h → JSON.generate → script-safe string)
        ▼
StructuredData::Rails::Helper       (optional; html_safe <script> tag in views)

StructuredData::Profiles::Google    (v0.2; warnings only, never mutates output)
```

### Entity DSL

```ruby
module StructuredData
  class SportsTeam < Organization          # inheritance mirrors Schema.org only where useful
    schema_type "SportsTeam"
    property :sport,     String            # → "sport"
    property :athlete,   Person,  many: true
    property :coach,     Person,  many: true
    property :member_of, [SportsOrganization, Ref]  # union; Ref = {"@id": ...}
  end
end
```

Rules:

- **Keyword-only constructor.** Unknown keywords raise `StructuredData::UnknownPropertyError`.
- **`nil` and empty arrays are omitted.** This makes conditional properties free:
  `image: post.image_url`.
- **One-or-many.** A property declared `many: true` accepts a single value or an array.
  It serializes a single value as a scalar and several as an array. Other properties
  reject arrays.
- **Name mapping:** `snake_case` → `lowerCamelCase` by default, with `property :x, as: "y"`
  as an override.
- **Value types:**
  - `String`
  - `URL` (absolute `http(s)` only, validated with `URI`)
  - `Date` / `Time` / `DateTime` (ISO 8601; `Time` keeps its offset)
  - `Integer`, `Float` / `Numeric`
  - `true` / `false`
  - `Enum` (e.g. `EventStatus::SCHEDULED` → `"https://schema.org/EventScheduled"`)
  - an `Entity` subclass
  - `Ref`
  - a union of any of these
- **No implicit coercion between unrelated types.** A `String` given for an `Integer`
  property raises. `Integer` → `Float` widening is allowed.
- **Errors carry a path,** e.g. `NewsArticle.author[1].url: expected absolute http(s) URL,
  got "/people/x"`. One base class, `StructuredData::Error < StandardError`, and a
  `ValidationError` subclass.
- **Entities are immutable** (frozen after construction). `#with(**changes)` returns a copy.
- **`id:`** sets `@id`. `StructuredData::Ref.new("https://example.com/#organization")`
  refers to a node without repeating it, and `entity.ref` builds a `Ref` from an entity
  that has an `id:` (it raises if there is none). Inside a `Graph`, a second full node
  with an `@id` already present becomes a `Ref`, so each entity is described once.
- **`@id` values are chosen by the client.** The gem validates only "absolute URI". To
  make the common convention easy, it ships `StructuredData::Ids`, a plain value object with
  no global state:
  `Ids.new(base_url)` has `#organization` (`<base>/#organization`), `#website`,
  `#site(name)` (`<base>/#<name>`), `#page(url_or_path)` (the absolute URL, fragment
  stripped) and `#entity(url_or_path, kind)` (`<url>#<kind>`). Relative paths resolve
  against `base_url`. Using it is optional.
- **Escape hatch:** `extra: { "sameAs" => [...] }` is merged verbatim, after validation of
  declared properties. It may not override `@type`, `@context` or declared keys. This keeps
  clients unblocked between releases (lesson from unhead).

### Serialization

- `#to_h` returns a string-keyed Hash. Key order is `@context` (root only), `@type`, `@id`,
  then properties in declaration order (parent class first), then `extra`. That makes the
  output deterministic and snapshot-testable.
- `#to_json_ld(pretty: false)` returns a JSON String via `JSON.generate(hash, script_safe: true)`.
  `script_safe` escapes `/` and U+2028/2029. We then also replace `<` `>` `&` with
  `\u003c` `\u003e` `\u0026`. This is the escaping schema-dts and `ERB::Util.json_escape`
  use, so it is safe inside `<script>` regardless of the template engine.
  Non-ASCII text stays as UTF-8 (no `ascii_only`).
- `StructuredData::Graph.new(*nodes).to_json_ld` returns
  `{"@context": "https://schema.org", "@graph": [...]}`. Nested entities never repeat
  `@context`.
- `StructuredData.script_tag(entity_or_graph)` returns the full
  `<script type="application/ld+json">…</script>` String. It is pure Ruby and not
  `html_safe` (core knows nothing about Rails).
- No global configuration in v0.1. This matches json 3, which dropped mutable global defaults.
  Site-wide values such as the base URL and `inLanguage` are passed explicitly, e.g. through
  an `Ids` instance the client creates.

### Rails integration (`lib/structured_data/rails/*`, opt-in)

- Load it with `require "structured_data/rails"` (or have Bundler `require:` it). It is
  not loaded by `require "structured_data"`.
- The Railtie includes a helper into `ActionView`:
  `structured_data_tag(*entities)` → one entity renders as a document, several render as a
  `@graph`. It returns an `html_safe` string built from the core `script_tag`.
- The gem has no runtime dependency on `railties`. CI tests it against Rails 8.0 and 8.1.

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
| Stdlib used | `json`, `uri`, `date`, `time` | No ActiveSupport, no Zeitwerk (plain `require_relative`; about 25 files). |
| Dev deps | `minitest ~> 6.0`, `rake`, `rubocop` + `rubocop-minitest` + `rubocop-performance` | Declared in the `Gemfile`, not the gemspec (current Bundler convention). |
| Rails (test only) | `gemfiles/rails_8_0.gemfile`, `gemfiles/rails_8_1.gemfile` | Use the `BUNDLE_GEMFILE` env in the CI matrix. No Appraisal needed. |

### Repository layout

```
structured-data-rb/
├── lib/structured_data.rb
├── lib/structured_data/{version,error,types,property,entity,ref,ids,graph,serializer}.rb
├── lib/structured_data/entities/*.rb
├── lib/structured_data/rails.rb, rails/{railtie,helper}.rb
├── sig/structured_data.rbs            # public API signatures (P1)
├── test/test_helper.rb
├── test/structured_data/**/*_test.rb
├── test/fixtures/*.json               # golden JSON-LD outputs
├── test/rails/*_test.rb               # run only with a Rails gemfile
├── test/dummy/                        # minimal Rails app for end-to-end checks
├── gemfiles/rails_8_{0,1}.gemfile
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
- **Validation tests:** every error message is asserted, including its path.
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
- `rails`: Ruby 4.0 × `rails_8_0` / `rails_8_1` gemfiles. Runs `bundle exec rake test:rails`.
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
| 2 | Core: `Entity`, `property`, scalar types, `to_h`, serializer + escaping | Escaping and key-order tests pass. |
| 3 | Nesting, `many:`, unions, `Ref`, `id:`, `#ref`, `Ids`, `Graph` (with duplicate-`@id` collapsing) | Graph fixture passes. |
| 4 | Validation errors with paths. Unknown-key rejection. `extra:` | Every error path is tested. |
| 5 | Shared entities: Thing, Organization, Person, ImageObject, Place, WebSite, WebPage, BreadcrumbList/ListItem | Fixtures pass. |
| 6 | NewsArticle/Article, SportsOrganization, SportsTeam, StadiumOrArena, SportsEvent (+ `subEvent`), `EventStatus` enum | All sports fixtures pass. |
| 7 | Movie + AggregateRating | Movie fixture passes. |
| 8 | Optional Rails Railtie + `structured_data_tag` | Rails 8.0/8.1 CI jobs are green. |
| 9 | End-to-end check in a sample Rails app (`test/dummy`): article, breadcrumbs, team, person, event pages | Rich Results Test passes for article and breadcrumb. No warnings we can't explain. |
| 10 | Release 0.1.0 through trusted publishing | The gem is installable. Attestation is visible on rubygems.org. |
| 11 | Retro: Google profile (warnings), RBS, codegen decision | Issues filed for v0.2. |

## 7. Risks and open questions

- **Scores and live data.** Schema.org has no score property. Docs and examples must not
  emulate one through `extra:`.
- **Event rich results.** Google's Event feature targets attendable events. Sports pages
  may get entity understanding but no visual rich result. Article and Breadcrumb are the
  measurable wins. Set expectations accordingly.
- **Decided: error messages are English only,** like all names and examples in the docs.
- **Decided: clients choose `@id` values; the gem provides helpers.** That means `id:`, `Ref`,
  `#ref`, `Graph` de-duplication and the optional `Ids` builder for the common convention
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
