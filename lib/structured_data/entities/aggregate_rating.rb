# frozen_string_literal: true

module StructuredData
  # https://schema.org/AggregateRating
  class AggregateRating < Thing
    properties :rating_value, :best_rating, :worst_rating, :rating_count, :review_count, :item_reviewed
  end
end
