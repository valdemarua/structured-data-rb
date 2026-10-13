# frozen_string_literal: true

module StructuredData
  # https://schema.org/Person
  class Person < Thing
    properties :given_name, :family_name, :birth_place, :nationality, :gender, :job_title, :affiliation,
               :member_of, :works_for, :height, :weight
    date_properties :birth_date
  end
end
