# frozen_string_literal: true

module StructuredData
  # A reference to a node described elsewhere: {"@id": "..."}.
  #
  #   StructuredData::Ref.new("https://example.com/#organization")
  class Ref
    ABSOLUTE_URI = /\A[a-z][a-z\d+.-]*:\S+\z/i

    attr_reader :id

    def self.check_id!(id, owner)
      return id.dup.freeze if id.is_a?(String) && ABSOLUTE_URI.match?(id)

      raise ValidationError, "#{owner} id: expected an absolute URI, got #{id.inspect}"
    end

    def initialize(id)
      @id = self.class.check_id!(id, "Ref")
      freeze
    end

    def to_h = { "@id" => id }

    def ==(other) = other.is_a?(Ref) && other.id == id
    alias eql? ==

    def hash = [Ref, id].hash
  end
end
