# frozen_string_literal: true

require "test_helper"

class ExtraTest < Minitest::Test
  Thing = TestEntities::Thing
  Ref = StructuredData::Ref

  def test_extra_properties_come_after_declared_ones
    thing = Thing.new(extra: { "sameAs" => ["https://www.wikidata.org/wiki/Q42"] }, name: "Jane Doe")

    assert_equal %w[@type name sameAs], thing.to_h.keys
    assert_equal ["https://www.wikidata.org/wiki/Q42"], thing.to_h["sameAs"]
  end

  def test_extra_values_are_kept_as_given
    extra = { "award" => "MVP", "score" => 9.5, "active" => true, "nothing" => nil,
              "nested" => { "a" => [1, { "b" => "c" }] } }

    assert_equal extra, Thing.new(extra: extra).to_h.except("@type")
  end

  def test_extra_values_can_be_entities_and_refs
    thing = Thing.new(extra: { "subjectOf" => Thing.new(name: "Story"), "owner" => Ref.new("https://example.com/#a") })

    assert_equal({ "@type" => "Thing", "name" => "Story" }, thing.to_h["subjectOf"])
    assert_equal({ "@id" => "https://example.com/#a" }, thing.to_h["owner"])
  end

  def test_extra_must_be_a_hash
    error = assert_raises(StructuredData::ValidationError) { Thing.new(extra: [1]) }

    assert_equal "Thing extra: expected a Hash, got Array", error.message
  end

  def test_extra_keys_must_be_strings
    error = assert_raises(StructuredData::ValidationError) { Thing.new(extra: { same_as: "x" }) }

    assert_equal "Thing extra[:same_as]: expected a String key, got Symbol", error.message
  end

  def test_extra_cannot_set_keywords
    error = assert_raises(StructuredData::ValidationError) { Thing.new(extra: { "@type" => "Person" }) }

    assert_equal 'Thing extra["@type"]: keys starting with @ are not allowed', error.message
  end

  def test_extra_cannot_override_declared_properties
    error = assert_raises(StructuredData::ValidationError) { Thing.new(extra: { "name" => "x" }) }

    assert_equal 'Thing extra["name"]: name is a declared property, use the name: keyword instead', error.message
  end

  def test_extra_rejects_non_json_values
    error = assert_raises(StructuredData::ValidationError) { Thing.new(extra: { "when" => [Object.new] }) }

    assert_equal 'Thing extra["when"][0]: expected a JSON value, an entity or a reference, got Object', error.message
  end
end
