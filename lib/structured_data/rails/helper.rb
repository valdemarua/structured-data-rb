# frozen_string_literal: true

module StructuredData
  module Rails
    # View helper, included into ActionView by the Railtie.
    module Helper
      # Renders one or more entities as a single JSON-LD <script> tag (one @graph document).
      #
      #   <%= structured_data_tag(organization, article) %>
      def structured_data_tag(*entities)
        StructuredData.script_tag(*entities).html_safe
      end
    end
  end
end
