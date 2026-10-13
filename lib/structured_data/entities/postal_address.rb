# frozen_string_literal: true

module StructuredData
  # https://schema.org/PostalAddress
  class PostalAddress < Thing
    properties :street_address, :address_locality, :address_region, :postal_code, :address_country
  end
end
