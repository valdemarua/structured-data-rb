# frozen_string_literal: true

module StructuredData
  # https://schema.org/CreativeWork
  class CreativeWork < Thing
    properties :headline, :alternative_headline, :author, :creator, :publisher, :in_language, :about, :mentions,
               :is_part_of, :keywords, :genre, :content_rating, :aggregate_rating
    url_properties :thumbnail_url
    date_properties :date_created, :date_published, :date_modified
  end
end
