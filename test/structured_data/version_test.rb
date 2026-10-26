# frozen_string_literal: true

require "test_helper"

class VersionTest < Minitest::Test
  def test_version_is_semver
    assert_match(/\A\d+\.\d+\.\d+(\.[0-9A-Za-z.]+)?\z/, StructuredData::VERSION)
  end

  # CI runs the suite on json 2.7 (the floor: script_safe), the newest 2.x and 3.x.
  def test_loaded_json_satisfies_the_gemspec
    gemspec = Gem::Specification.load(File.expand_path("../../structured-data-rb.gemspec", __dir__))
    requirement = gemspec.dependencies.find { |dependency| dependency.name == "json" }.requirement

    assert requirement.satisfied_by?(Gem::Version.new(JSON::VERSION)), "json #{JSON::VERSION} is outside #{requirement}"
  end

  def test_json_supports_script_safe
    assert_equal '"\\u2028\\/"', JSON.generate("\u2028/", script_safe: true)
  end
end
