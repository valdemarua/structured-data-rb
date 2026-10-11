# frozen_string_literal: true

require "test_helper"
require "rails"
require "action_controller/railtie"
require "structured_data/rails"

# A minimal Rails app, so the Railtie runs exactly as it would in a client app.
class HelperTestApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "test"
end
HelperTestApp.initialize!

class HelperTest < Minitest::Test
  def test_helper_is_available_in_views
    assert_includes ActionView::Base.ancestors, StructuredData::Rails::Helper
  end

  def test_renders_one_graph_document_without_double_escaping
    team = StructuredData::SportsTeam.new(name: "Rovers & Co </script>")
    html = render("<%= structured_data_tag(team) %>", team: team)

    assert_equal StructuredData.script_tag(team), html
    assert_includes html, "Rovers \\u0026 Co \\u003c\\/script\\u003e"
  end

  def test_renders_several_entities
    html = render("<%= structured_data_tag(a, b) %>",
                  a: StructuredData::Organization.new(name: "Example News"),
                  b: StructuredData::WebSite.new(name: "Example News"))
    json = html[%r{<script type="application/ld\+json">(.*)</script>}m, 1]

    assert_equal %w[Organization WebSite], JSON.parse(json)["@graph"].map { _1["@type"] }
  end

  private

  def render(template, **locals)
    ActionController::Base.render(inline: template, locals: locals)
  end
end
