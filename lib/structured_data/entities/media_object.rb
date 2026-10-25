# frozen_string_literal: true

module StructuredData
  # https://schema.org/MediaObject
  class MediaObject < CreativeWork
    properties :width, :height, :encoding_format, :duration
    url_properties :content_url, :embed_url
    date_properties :upload_date
  end
end
