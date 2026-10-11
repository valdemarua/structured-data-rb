# frozen_string_literal: true

module StructuredData
  module Rails
    # Makes structured_data_tag available in all views.
    class Railtie < ::Rails::Railtie
      initializer "structured_data.helper" do
        ActiveSupport.on_load(:action_view) { include StructuredData::Rails::Helper }
      end
    end
  end
end
