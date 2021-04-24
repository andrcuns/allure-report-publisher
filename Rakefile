# frozen_string_literal: true

require "rake"

require_relative "lib/allure_report_publisher"
Dir["tasks/*.rake"].each { |f| load(f) }

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"
RuboCop::RakeTask.new

task default: %i[spec rubocop]
