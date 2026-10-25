# frozen_string_literal: true

module StructuredData
  # https://schema.org/TVSeries
  class TVSeries < CreativeWork
    properties :director, :actor, :production_company, :country_of_origin, :trailer, :number_of_seasons,
               :number_of_episodes, :contains_season, :episode
    date_properties :start_date, :end_date
  end
end
