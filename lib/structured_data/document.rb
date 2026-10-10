# frozen_string_literal: true

# Builds the JSON-LD document. This is the only place JSON is generated.
module StructuredData
  CONTEXT = "https://schema.org"

  # Characters escaped on top of json's script_safe, so the output is safe inside <script>.
  SCRIPT_ESCAPES = { "<" => "\\u003c", ">" => "\\u003e", "&" => "\\u0026" }.freeze

  class << self
    # One "@graph" document for one or more entities, as a Hash.
    def graph(*entities)
      nodes = entities.flatten.compact.map do |entity|
        raise ArgumentError, "expected a StructuredData::Entity, got #{entity.class}" unless entity.is_a?(Entity)

        entity.to_h
      end
      { "@context" => CONTEXT, "@graph" => nodes }
    end

    # The document as a JSON string that is safe to embed in a <script> tag.
    def json_ld(*entities, pretty: false)
      document = graph(*entities)
      json = pretty ? JSON.pretty_generate(document, script_safe: true) : JSON.generate(document, script_safe: true)
      json.gsub(/[<>&]/, SCRIPT_ESCAPES)
    end

    # The document wrapped in <script type="application/ld+json">. Not marked html_safe.
    def script_tag(*entities)
      %(<script type="application/ld+json">#{json_ld(*entities)}</script>)
    end
  end
end
