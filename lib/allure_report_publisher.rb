# frozen_string_literal: true

require "require_all"
require "parallel"
require "dry/cli"
require "pry"

require_rel "allure_report_publisher/helpers"
require_rel "allure_report_publisher/**/*.rb"

module Allure
  module Publisher
    module Commands
      extend Dry::CLI::Registry

      register "version", Version, aliases: ["-v", "--version"]

      register "upload" do |prefix|
        prefix.register "s3", UploadS3
      end
    end
  end
end
