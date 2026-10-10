# frozen_string_literal: true

require "test_helper"

class VersionTest < Minitest::Test
  def test_version_is_semver
    assert_match(/\A\d+\.\d+\.\d+(\.[0-9A-Za-z.]+)?\z/, StructuredData::VERSION)
  end

  def test_uses_json3
    assert_equal 3, JSON::VERSION.split(".").first.to_i
  end
end
