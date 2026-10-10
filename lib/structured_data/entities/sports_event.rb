# frozen_string_literal: true

module StructuredData
  # https://schema.org/SportsEvent
  class SportsEvent < Event
    properties :home_team, :away_team, :competitor, :sport
  end
end
