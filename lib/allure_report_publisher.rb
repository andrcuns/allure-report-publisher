# frozen_string_literal: true

require "require_all"
require "parallel"
require "dry/cli"

require_rel "allure_report_publisher/lib/helpers/*.rb"
require_rel "allure_report_publisher/**/*.rb"

module Publisher
  # CLI commands
  #
  module Commands
    extend Dry::CLI::Registry

    register "version", Version, aliases: ["-v", "--version"]
    register "upload", Upload, aliases: ["u"]
  end
end

Publisher::Commands.before("upload") { Publisher::Helpers.validate_allure_cli_present }
