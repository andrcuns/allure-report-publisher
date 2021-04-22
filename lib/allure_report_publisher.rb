# frozen_string_literal: true

require "require_all"
require "dry/cli"
require "cli/ui"
require "parallel"
require "pry"

require_rel "allure_report_publisher/helpers"
require_rel "allure_report_publisher/**/*.rb"

CLI::UI::StdoutRouter.enable

module Allure
  module Publisher
    module Commands
      extend Dry::CLI::Registry

      register "upload", Upload
    end
  end
end
