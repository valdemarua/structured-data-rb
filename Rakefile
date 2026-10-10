# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create(:test) do |t|
  t.test_globs = ["test/structured_data/**/*_test.rb"]
end

Minitest::TestTask.create(:"test:rails") do |t|
  t.test_globs = ["test/rails/**/*_test.rb"]
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # RuboCop is not part of the Rails gemfiles.
end

task default: %i[test rubocop]
