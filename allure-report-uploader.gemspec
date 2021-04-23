# frozen_string_literal: true

require_relative "lib/allure_report_publisher/version"

Gem::Specification.new do |spec|
  spec.version       = Publisher::VERSION
  spec.name          = "allure-report-publisher"
  spec.authors       = ["Andrejs Cunskis"]
  spec.email         = ["andrejs.cunskis@gmail.com"]

  spec.summary       = "Allure report uploader"
  spec.description   = "Upload allure reports to different file storage providers"
  spec.homepage      = "https://github.com/andrcuns/allure-report-uploader"
  spec.license       = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/andrcuns/allure-report-uploader",
    "changelog_uri" => "https://github.com/andrcuns/allure-report-uploader/releases",
    "documentation_uri" => "https://github.com/andrcuns/allure-report-uploader/blob/master/README.md",
    "bug_tracker_uri" => "https://github.com/andrcuns/allure-report-uploader/issues"
  }

  spec.files         = Dir["README.md", "lib/**/*", "bin/allure-report-publisher"]
  spec.bindir        = "bin"
  spec.executables   = ["allure-report-publisher"]
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-s3", "~> 1.93.1"
  spec.add_dependency "dry-cli", "~> 0.6.0"
  spec.add_dependency "parallel", "~> 1.20"
  spec.add_dependency "pastel", "~> 0.8.0"
  spec.add_dependency "require_all", "~> 3.0.0"
  spec.add_dependency "tty-spinner", "~> 0.9.3"
end
