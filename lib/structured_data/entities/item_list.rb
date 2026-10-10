# frozen_string_literal: true

module StructuredData
  # https://schema.org/ItemList
  class ItemList < Thing
    properties :item_list_element, :number_of_items
    enum :item_list_order, %w[ItemListOrderAscending ItemListOrderDescending ItemListUnordered]
  end
end
