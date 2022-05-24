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

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/andrcuns/allure-report-uploader",
    "changelog_uri" => "https://github.com/andrcuns/allure-report-uploader/releases",
    "documentation_uri" => "https://github.com/andrcuns/allure-report-uploader/blob/master/README.md",
    "bug_tracker_uri" => "https://github.com/andrcuns/allure-report-uploader/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files         = Dir["README.md", "lib/**/*", "bin/allure-report-publisher"]
  spec.bindir        = "bin"
  spec.executables   = ["allure-report-publisher"]
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-s3", ">= 1.93.1", "< 1.115.0"
  spec.add_dependency "dry-cli", ">= 0.6", "< 0.8"
  spec.add_dependency "gitlab", "~> 4.17"
  spec.add_dependency "google-cloud-storage", "~> 1.31"
  spec.add_dependency "mini_mime", "~> 1.1"
  spec.add_dependency "octokit", "~> 4.21"
  spec.add_dependency "parallel", "~> 1.20"
  spec.add_dependency "pastel", "~> 0.8.0"
  spec.add_dependency "require_all", "~> 3.0.0"
  spec.add_dependency "terminal-table", "~> 3.0"
  spec.add_dependency "tty-spinner", "~> 0.9.3"

  spec.add_development_dependency "allure-rspec", "~> 2.18.0"
  spec.add_development_dependency "climate_control", "~> 1.0.1"
  spec.add_development_dependency "pry-byebug", "~> 3.9"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.11"
  spec.add_development_dependency "rubocop", "~> 1.27"
  spec.add_development_dependency "rubocop-performance", "~> 1.13"
  spec.add_development_dependency "rubocop-rake", "~> 0.6.0"
  spec.add_development_dependency "rubocop-rspec", "~> 2.9"
  spec.add_development_dependency "simplecov", "~> 0.21.2"
  spec.add_development_dependency "simplecov-console", "~> 0.9.1"
  spec.add_development_dependency "solargraph", "~> 0.45.0"
end
