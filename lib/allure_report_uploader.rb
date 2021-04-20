# frozen_string_literal: true

require "require_all"
require "dry/cli"

require_rel "allure_report_uploader/**/*.rb"

module Allure
  module Uploader
    module Commands
      extend Dry::CLI::Registry

      register "upload", Upload
    end
  end
end
