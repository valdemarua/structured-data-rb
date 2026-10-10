# frozen_string_literal: true

# Entity classes used only by the core tests. Real Schema.org types live in lib/structured_data/entities.
module TestEntities
  class Thing < StructuredData::Entity
    properties :name, :description, :rating
    url_properties :url, :image
  end

  class Event < Thing
    properties :location, :is_accessible_for_free
    date_properties :start_date
    enum :event_status, %w[EventScheduled EventCancelled]
  end
end
