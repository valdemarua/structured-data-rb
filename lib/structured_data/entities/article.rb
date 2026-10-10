# frozen_string_literal: true

module StructuredData
  # https://schema.org/Article
  class Article < CreativeWork
    properties :article_section, :article_body, :word_count
  end
end
