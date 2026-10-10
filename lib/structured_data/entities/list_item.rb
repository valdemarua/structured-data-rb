# frozen_string_literal: true

module StructuredData
  # https://schema.org/ListItem
  class ListItem < Thing
    properties :position
    url_properties :item
  end
end
