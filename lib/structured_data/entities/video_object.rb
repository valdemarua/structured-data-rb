# frozen_string_literal: true

module StructuredData
  # https://schema.org/VideoObject
  #
  # Google's video results require name, thumbnail_url and upload_date.
  class VideoObject < MediaObject
    properties :caption, :transcript
  end
end
