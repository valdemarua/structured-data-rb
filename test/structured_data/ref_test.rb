# frozen_string_literal: true

require "test_helper"

class RefTest < Minitest::Test
  Thing = TestEntities::Thing
  Event = TestEntities::Event
  Ref = StructuredData::Ref

  def test_ref_serializes_to_an_id_node
    assert_equal({ "@id" => "https://example.com/#organization" }, Ref.new("https://example.com/#organization").to_h)
  end

  def test_ref_accepts_any_absolute_uri
    assert_equal "urn:isbn:9780000000000", Ref.new("urn:isbn:9780000000000").id
  end

  def test_ref_rejects_relative_ids
    error = assert_raises(StructuredData::ValidationError) { Ref.new("#organization") }

    assert_equal 'Ref id: expected an absolute URI, got "#organization"', error.message
  end

  def test_refs_with_the_same_id_are_equal
    assert_equal Ref.new("https://example.com/#a"), Ref.new("https://example.com/#a")
    refute_equal Ref.new("https://example.com/#a"), Ref.new("https://example.com/#b")
  end

  def test_entity_id_comes_after_type
    thing = Thing.new(name: "Rovers", id: "https://example.com/teams/rovers#team")

    assert_equal %w[@type @id name], thing.to_h.keys
    assert_equal "https://example.com/teams/rovers#team", thing.id
  end

  def test_entity_rejects_relative_id
    error = assert_raises(StructuredData::ValidationError) { Thing.new(id: "/teams/rovers") }

    assert_equal 'Thing id: expected an absolute URI, got "/teams/rovers"', error.message
  end

  def test_entity_ref
    thing = Thing.new(id: "https://example.com/#organization", name: "Example News")

    assert_equal Ref.new("https://example.com/#organization"), thing.ref
  end

  def test_entity_ref_without_id
    error = assert_raises(StructuredData::Error) { Thing.new(name: "Rovers").ref }

    assert_equal "Thing has no id, so it cannot be referenced", error.message
  end

  def test_refs_as_property_values
    event = Event.new(location: Ref.new("https://example.com/#arena"), image: [Ref.new("https://example.com/#logo")])

    assert_equal({ "@id" => "https://example.com/#arena" }, event.to_h["location"])
    assert_equal [{ "@id" => "https://example.com/#logo" }], event.to_h["image"]
  end

  def test_graph_keeps_the_first_entity_for_each_id
    first = Thing.new(id: "https://example.com/#organization", name: "First")
    second = Thing.new(id: "https://example.com/#organization", name: "Second")
    other = Thing.new(name: "No id")

    nodes = StructuredData.graph(first, other, second, other)["@graph"]

    assert_equal(["First", "No id"], nodes.map { _1["name"] })
  end

  def test_graph_keeps_entities_without_id
    nodes = StructuredData.graph(Thing.new(name: "A"), Thing.new(name: "A"))["@graph"]

    assert_equal 2, nodes.size
  end
end
