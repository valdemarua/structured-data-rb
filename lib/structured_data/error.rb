# frozen_string_literal: true

module StructuredData
  # Base class for every error raised by the gem.
  class Error < StandardError; end

  # A property value has the wrong kind or format.
  class ValidationError < Error; end

  # An entity was given a property it does not declare.
  class UnknownPropertyError < Error; end
end
