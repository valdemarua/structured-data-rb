# frozen_string_literal: true

module StructuredData
  # https://schema.org/SportsTeam
  class SportsTeam < SportsOrganization
    properties :athlete, :coach
  end
end
