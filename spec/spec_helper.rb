# frozen_string_literal: true

require "simplecov"
require "rspec"
require "allure-rspec"
require "stringio"
require "climate_control"
require "rspec_junit_formatter"
require "debug" unless ENV["CI"]

require "allure_report_publisher"

require_relative "cli_helper"
require_relative "mock_helper"
require_relative "output_helper"

# Force color output to avoid different behaviour on CI
Publisher::Helpers.instance_variable_set(:@pastel, Pastel.new(enabled: true))

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.prepend_before do
    allow(Publisher::Providers::Info::Gitlab).to receive(:instance) { Publisher::Providers::Info::Gitlab.send(:new) }
    allow(Publisher::Providers::Info::Github).to receive(:instance) { Publisher::Providers::Info::Github.send(:new) }
  end
end

AllureRspec.configure do |c|
  c.results_directory = "reports/allure-results"
  c.clean_results_directory = true
end
