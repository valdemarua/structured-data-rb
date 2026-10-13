# frozen_string_literal: true

require "test_helper"
require "action_view"
require "active_support/json"

# Smoke test: the supported Rails versions load alongside json 3.
class RailsLoadingTest < Minitest::Test
  def test_action_view_loads_with_json3
    assert_equal 3, JSON::VERSION.split(".").first.to_i
    assert_equal({ "a" => 1 }.to_json, ActiveSupport::JSON.encode({ "a" => 1 }))
    assert_equal({ "a" => 1 }, ActiveSupport::JSON.decode('{"a":1}'))
  end
end
