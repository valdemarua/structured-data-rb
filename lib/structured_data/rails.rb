# frozen_string_literal: true

# Optional Rails integration: require "structured_data/rails" to get the structured_data_tag view helper.
require "structured_data"
require_relative "rails/helper"
require_relative "rails/railtie" if defined?(::Rails::Railtie)
