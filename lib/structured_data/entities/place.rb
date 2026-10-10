# frozen_string_literal: true

module StructuredData
  # https://schema.org/Place
  class Place < Thing
    properties :address, :latitude, :longitude, :maximum_attendee_capacity
  end
end
