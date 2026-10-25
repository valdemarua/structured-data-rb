# frozen_string_literal: true

module StructuredData
  # https://schema.org/TVEpisode
  class TVEpisode < CreativeWork
    properties :director, :actor, :duration, :production_company, :country_of_origin, :trailer, :episode_number,
               :part_of_season, :part_of_series
  end
end
