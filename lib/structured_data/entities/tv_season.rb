# frozen_string_literal: true

module StructuredData
  # https://schema.org/TVSeason
  class TVSeason < CreativeWork
    properties :director, :actor, :production_company, :country_of_origin, :trailer, :season_number,
               :number_of_episodes, :episode, :part_of_series
    date_properties :start_date, :end_date
  end
end
