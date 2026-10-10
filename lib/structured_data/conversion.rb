# frozen_string_literal: true

module StructuredData
  # Checks and converts property values for Entity. Raises ValidationError for values that
  # cannot be right; everything else is kept as given.
  module Conversion
    URL = %r{\Ahttps?://[^\s/?#]+\S*\z}
    ISO_8601 = /\A\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?)?)?\z/
    SCHEMA_ORG = "https://schema.org/"
    # Time, Date, DateTime and any other object that formats itself as ISO 8601.
    TIME_LIKE = ->(value) { value.respond_to?(:iso8601) }

    private

    def convert(property, value, label = property.name)
      case value
      when nil then nil
      when Array then convert_array(property, value, label)
      when Entity, Ref then value
      when String then convert_string(property, value, label)
      when TIME_LIKE then convert_time(property, value, label)
      when Integer, Float, true, false then convert_scalar(property, value, label)
      else invalid(label, "expected text, a number, a boolean, a date, an entity or a reference, got #{value.class}")
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

    def invalid(label, message)
      raise ValidationError, "#{schema_type} #{label}: #{message}"
    end
  end
end
