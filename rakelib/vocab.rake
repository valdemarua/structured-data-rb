# frozen_string_literal: true

desc "Check entity declarations and test fixtures against the pinned Schema.org vocabulary"
task :vocab do
  $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
  require "structured_data"
  require_relative "../test/support/vocabulary"

  vocabulary = Vocabulary.new(Vocabulary.fetch(File.expand_path("../tmp", __dir__)))

  entities = ObjectSpace.each_object(Class).select { _1 < StructuredData::Entity && _1.name&.start_with?("StructuredData::") }
  fixtures = Dir[File.expand_path("../test/fixtures/*.json", __dir__)]

  errors = entities.flat_map { vocabulary.check_entity(_1) } +
           fixtures.flat_map { vocabulary.check_document(JSON.parse(File.read(_1)), File.basename(_1)) }

  abort(errors.join("\n")) if errors.any?

  puts "Schema.org #{Vocabulary::VERSION}: #{entities.size} entities and #{fixtures.size} fixtures OK"
end
