# frozen_string_literal: true

module StructuredData
  # https://schema.org/ImageObject
  class ImageObject < CreativeWork
    properties :width, :height, :caption, :encoding_format
    url_properties :content_url
  end
end
