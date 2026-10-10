# frozen_string_literal: true

module StructuredData
  # https://schema.org/Organization
  class Organization < Thing
    properties :legal_name, :address, :email, :telephone, :location, :member_of, :founder
    url_properties :logo
    date_properties :founding_date
  end
end
