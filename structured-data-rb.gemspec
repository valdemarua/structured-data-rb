# frozen_string_literal: true

require_relative "lib/structured_data/version"

Gem::Specification.new do |spec|
  spec.name = "structured-data-rb"
  spec.version = StructuredData::VERSION
  spec.authors = ["valdemarua"]

  spec.summary = "Schema.org JSON-LD for Ruby: validated entities, @graph and safe <script> rendering."
  spec.description = "Build Schema.org structured data in plain Ruby with type-checked entities, " \
                     "@id references and deterministic, script-safe JSON-LD output. " \
                     "Optional Rails view helper."
  spec.homepage = "https://github.com/valdemarua/structured-data-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "https://rubydoc.info/gems/structured-data-rb",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "json", ">= 2.7", "< 4"
end
