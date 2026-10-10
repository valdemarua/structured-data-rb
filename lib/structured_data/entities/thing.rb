# frozen_string_literal: true

module StructuredData
  # https://schema.org/Thing
  class Thing < Entity
    properties :name, :alternate_name, :description, :identifier
    url_properties :url, :image, :same_as, :main_entity_of_page
  end
end
