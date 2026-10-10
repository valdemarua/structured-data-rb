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
    Property = Data.define(:name, :key, :kind, :allowed)

    RESERVED = %i[id type context extra].freeze
    URL = %r{\Ahttps?://[^\s/?#]+\S*\z}
    ISO_8601 = /\A\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?)?)?\z/
    SCHEMA_ORG = "https://schema.org/"

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

    def initialize(**values)
      raise NotImplementedError, "#{self.class} is abstract" if instance_of?(Entity)

      declared = self.class.declared_properties
      @values = values.each_with_object({}) do |(name, value), converted|
        property = declared.fetch(name) { unknown_property(name) }
        value = convert(property, value)
        converted[property.key] = value unless value.nil?
      end.freeze
      freeze
    end

    def schema_type = self.class.schema_type

    # The node as a string-keyed Hash, without "@context".
    def to_h
      { "@type" => schema_type }.merge(@values.transform_values { serialize(_1) })
    end

    private

    def convert(property, value, label = property.name)
      case value
      when nil then nil
      when Array then convert_array(property, value, label)
      when Entity then value
      when String then convert_string(property, value, label)
      when Time, Date then convert_time(property, value, label)
      when Integer, Float, true, false then convert_scalar(property, value, label)
      else invalid(label, "expected text, a number, a boolean, a date or an entity, got #{value.class}")
      end
    end

    def convert_array(property, values, label)
      converted = values.each_with_index.filter_map { |item, i| convert(property, item, "#{label}[#{i}]") }
      converted.empty? ? nil : converted.freeze
    end

    def convert_string(property, value, label)
      problem = string_problem(property, value)
      invalid(label, "expected #{problem}, got #{value.inspect}") if problem
      return "#{SCHEMA_ORG}#{value}" if property.kind == :enum

      value.frozen? ? value : value.dup.freeze
    end

    # What the string should have been, or nil when it is fine.
    def string_problem(property, value)
      case property.kind
      when :url then "an absolute http(s) URL" unless URL.match?(value)
      when :date then "an ISO 8601 date" unless ISO_8601.match?(value)
      when :enum then "one of #{property.allowed.join(", ")}" unless property.allowed.include?(value)
      end
    end

    # DateTime is a Date subclass, so test it first. ActiveSupport::TimeWithZone reports itself as a Time.
    def convert_time(property, value, label)
      invalid(label, "expected a URL, got #{value.class}") if property.kind == :url
      invalid(label, "expected a Schema.org enum name, got #{value.class}") if property.kind == :enum
      value.iso8601.freeze
    end

    def convert_scalar(property, value, label)
      invalid(label, "expected a string, got #{value.class}") unless property.kind == :text
      invalid(label, "expected a finite number, got #{value}") if value.is_a?(Float) && !value.finite?
      value
    end

    def serialize(value)
      case value
      when Entity then value.to_h
      when Array then value.map { serialize(_1) }
      else value
      end
    end

    def unknown_property(name)
      raise UnknownPropertyError, "#{schema_type} does not support property :#{name}"
    end

    def invalid(label, message)
      raise ValidationError, "#{schema_type} #{label}: #{message}"
    end
  end
end
