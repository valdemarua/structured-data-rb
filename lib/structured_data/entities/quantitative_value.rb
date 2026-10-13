# frozen_string_literal: true

module StructuredData
  # https://schema.org/QuantitativeValue
  #
  #   QuantitativeValue.new(value: 198, unit_code: "CMT") # UN/CEFACT unit codes, e.g. CMT, KGM
  class QuantitativeValue < Thing
    properties :value, :unit_code, :unit_text, :min_value, :max_value
  end
end
