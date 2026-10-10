# frozen_string_literal: true

require "test_helper"

class EntityTest < Minitest::Test
  Thing = TestEntities::Thing
  Event = TestEntities::Event

  def test_type_is_the_class_name
    assert_equal({ "@type" => "Thing", "name" => "Rovers" }, Thing.new(name: "Rovers").to_h)
  end

  def test_keys_are_camel_case_in_the_order_given
    event = Event.new(start_date: "2026-10-14", name: "Final", is_accessible_for_free: true)

    assert_equal %w[@type startDate name isAccessibleForFree], event.to_h.keys
  end

  def test_subclass_inherits_properties
    assert_equal "Final", Event.new(name: "Final").to_h["name"]
    assert_includes Event.declared_properties.keys, :url
    refute_includes Thing.declared_properties.keys, :start_date
  end

  def test_nil_and_empty_values_are_omitted
    thing = Thing.new(name: "Rovers", description: nil, image: [], url: [nil])

    assert_equal({ "@type" => "Thing", "name" => "Rovers" }, thing.to_h)
  end

  def test_single_values_and_arrays_are_kept_as_given
    assert_equal "https://example.com/a.png", Thing.new(image: "https://example.com/a.png").to_h["image"]
    assert_equal ["https://example.com/a.png"], Thing.new(image: ["https://example.com/a.png"]).to_h["image"]
  end

  def test_nested_entities
    event = Event.new(name: "Final", location: Thing.new(name: "Riverside Arena"))

    assert_equal({ "@type" => "Thing", "name" => "Riverside Arena" }, event.to_h["location"])
  end

  def test_arrays_of_entities
    event = Event.new(location: [Thing.new(name: "A"), Thing.new(name: "B")])

    assert_equal(%w[A B], event.to_h["location"].map { _1["name"] })
  end

  def test_numbers_and_booleans
    thing = Thing.new(rating: 4.5)
    event = Event.new(is_accessible_for_free: false)

    assert_in_delta(4.5, thing.to_h["rating"])
    refute event.to_h["isAccessibleForFree"]
  end

  def test_entities_are_frozen
    thing = Thing.new(name: +"Rovers", image: ["https://example.com/a.png"])

    assert_predicate thing, :frozen?
    assert_predicate thing.to_h["name"], :frozen?
  end

  def test_base_class_cannot_be_instantiated
    assert_raises(NotImplementedError) { StructuredData::Entity.new }
  end

  def test_reserved_property_names
    error = assert_raises(ArgumentError) { Class.new(StructuredData::Entity) { properties :id } }

    assert_equal "id is reserved", error.message
  end
end
