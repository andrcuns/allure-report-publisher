# frozen_string_literal: true

require "rake"

require_relative "lib/allure_report_publisher"

load "tasks/release.rake"
Publisher::ReleaseTask.new

load "tasks/version.rake"
Publisher::VersionTask.new

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:test)

desc("Run RSpec code examples with code coverage")
RSpec::Core::RakeTask.new("test:coverage") do
  ENV["COVERAGE"] = "true"
end

require "rubocop/rake_task"
RuboCop::RakeTask.new

task default: %i[rubocop test]
