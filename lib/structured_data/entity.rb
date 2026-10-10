# frozen_string_literal: true

module StructuredData
  # Base class for Schema.org types. The Schema.org type name is the class name.
  #
  #   class Event < Thing
  #     properties :location, :organizer
  #     date_properties :start_date, :end_date
  #     enum :event_status, %w[EventScheduled EventCancelled]
  #   end
  #
  # A subclass declares only its own properties and inherits the rest.
  class Entity
    include Conversion

    Property = Data.define(:name, :key, :kind, :allowed)

    RESERVED = %i[id type context extra].freeze

    class << self
      def properties(*names) = names.each { declare(_1, :text) }

      def url_properties(*names) = names.each { declare(_1, :url) }

      def date_properties(*names) = names.each { declare(_1, :date) }

      def enum(name, members) = declare(name, :enum, members.map(&:to_s).freeze)

      # All properties of this type, including inherited ones, by name.
      def declared_properties
        inherited = superclass <= Entity ? superclass.declared_properties : {}
        inherited.merge(own_properties)
      end

      def schema_type = name.split("::").last

      private

      def own_properties = (@own_properties ||= {})

      def declare(name, kind, allowed = nil)
        name = name.to_sym
        raise ArgumentError, "#{name} is reserved" if RESERVED.include?(name)

        key = name.to_s.gsub(/_([a-z\d])/) { ::Regexp.last_match(1).upcase }
        own_properties[name] = Property.new(name:, key:, kind:, allowed:)
      end
    end

    attr_reader :id

    def initialize(id: nil, **values)
      raise NotImplementedError, "#{self.class} is abstract" if instance_of?(Entity)

      @id = Ref.check_id!(id, schema_type) unless id.nil?
      @values = convert_values(values).freeze
      freeze
    end

    def schema_type = self.class.schema_type

    # The node as a string-keyed Hash, without "@context".
    def to_h
      node = { "@type" => schema_type }
      node["@id"] = id if id
      node.merge(@values.transform_values { serialize(_1) })
    end

    # A reference to this entity, for use in other entities.
    def ref
      raise Error, "#{schema_type} has no id, so it cannot be referenced" unless id

      Ref.new(id)
    end

    private

    def convert_values(values)
      declared = self.class.declared_properties
      values.each_with_object({}) do |(name, value), converted|
        property = declared.fetch(name) { unknown_property(name) }
        value = convert(property, value)
        converted[property.key] = value unless value.nil?
      end
    end

    def serialize(value)
      case value
      when Entity, Ref then value.to_h
      when Array then value.map { serialize(_1) }
      else value
      end
    end

    def unknown_property(name)
      raise UnknownPropertyError, "#{schema_type} does not support property :#{name}"
    end
  end
end
