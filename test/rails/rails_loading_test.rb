# frozen_string_literal: true

require "test_helper"
require "action_view"
require "active_support/json"

# Smoke test: each supported Rails version loads and round-trips JSON with the
# json version it resolves (2.x before Rails 8.1.4, 3.x from 8.1.4).
class RailsLoadingTest < Minitest::Test
  def test_action_view_loads_and_active_support_json_round_trips
    assert_equal({ "a" => 1 }.to_json, ActiveSupport::JSON.encode({ "a" => 1 }))
    assert_equal({ "a" => 1 }, ActiveSupport::JSON.decode('{"a":1}'))
  end
end
