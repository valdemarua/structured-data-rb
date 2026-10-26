# frozen_string_literal: true

require "test_helper"

class DocumentTest < Minitest::Test
  Thing = TestEntities::Thing

  def test_graph_for_one_entity
    assert_equal(
      { "@context" => "https://schema.org", "@graph" => [{ "@type" => "Thing", "name" => "Rovers" }] },
      StructuredData.graph(Thing.new(name: "Rovers"))
    )
  end

  def test_graph_for_several_entities_and_arrays
    graph = StructuredData.graph(Thing.new(name: "A"), [Thing.new(name: "B"), nil])

    assert_equal(%w[A B], graph["@graph"].map { _1["name"] })
  end

  def test_graph_rejects_non_entities
    error = assert_raises(ArgumentError) { StructuredData.graph({ "@type" => "Thing" }) }

    assert_equal "expected a StructuredData::Entity, got Hash", error.message
  end

  def test_json_ld
    assert_equal '{"@context":"https:\/\/schema.org","@graph":[{"@type":"Thing","name":"Rovers"}]}',
                 StructuredData.json_ld(Thing.new(name: "Rovers"))
  end

  def test_json_ld_escapes_for_script_tags
    json = StructuredData.json_ld(Thing.new(name: "</script><!-- & \u2028\u2029"))

    refute_match(/[<>&\u2028\u2029]/, json)
    assert_includes json, "\\u003c\\/script\\u003e\\u003c!-- \\u0026 \\u2028\\u2029"
    assert_equal "</script><!-- & \u2028\u2029", JSON.parse(json).dig("@graph", 0, "name")
  end

  def test_json_ld_keeps_non_ascii_readable
    json = StructuredData.json_ld(Thing.new(name: "Café Zürich 東京 🏀"))

    assert_includes json, "Café Zürich 東京 🏀"
  end

  def test_pretty_json_ld_is_also_escaped
    json = StructuredData.json_ld(Thing.new(name: "<b>"), pretty: true)

    assert_includes json, "\n"
    assert_includes json, "\\u003cb\\u003e"
  end

  def test_script_tag
    assert_equal '<script type="application/ld+json">' \
                 '{"@context":"https:\/\/schema.org","@graph":[{"@type":"Thing","name":"Rovers"}]}</script>',
                 StructuredData.script_tag(Thing.new(name: "Rovers"))
  end
end
