# frozen_string_literal: true

module StructuredData
  # https://schema.org/BreadcrumbList
  class BreadcrumbList < ItemList
    # Builds a list from [name, url] pairs. Positions start at 1, and an item without a URL
    # (usually the current page) gets no "item".
    #
    #   BreadcrumbList.from([["Home", "https://example.com/"], ["Teams"]])
    def self.from(crumbs, **properties)
      items = crumbs.each_with_index.map do |(name, url), index|
        ListItem.new(position: index + 1, name: name, item: url)
      end
      new(item_list_element: items, **properties)
    end
  end
end
