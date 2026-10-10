# frozen_string_literal: true

module StructuredData
  # https://schema.org/WebPage
  class WebPage < CreativeWork
    properties :breadcrumb, :primary_image_of_page
    date_properties :last_reviewed
  end
end
