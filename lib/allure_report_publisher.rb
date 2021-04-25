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

    register "upload" do |prefix|
      prefix.register "s3", UploadS3
    end
  end
end
