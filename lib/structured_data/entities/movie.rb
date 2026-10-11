# frozen_string_literal: true

module StructuredData
  # https://schema.org/Movie
  class Movie < CreativeWork
    properties :director, :actor, :duration, :production_company, :country_of_origin
  end
end
