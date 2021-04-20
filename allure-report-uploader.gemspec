# frozen_string_literal: true

require_relative "lib/allure_report_uploader/version"

Gem::Specification.new do |spec|
  spec.name          = "allure-report-uploader"
  spec.version       = Allure::Uploader::VERSION
  spec.authors       = ["Andrejs Cunskis"]
  spec.email         = ["andrejs.cunskis@gmail.com"]

  spec.summary       = "Allure report uploader"
  spec.description   = "Upload allure reports to different file storage providers"
  spec.homepage      = "https://github.com/andrcuns/allure-report-uploader"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/andrcuns/allure-report-uploader"
  spec.metadata["changelog_uri"] = "https://github.com/andrcuns/allure-report-uploader/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["allure-report-uploader"]
  spec.require_paths = ["lib"]

  spec.add_dependency "cli-ui", "~> 1.5"
  spec.add_dependency "dry-cli", "~> 0.6.0"
  spec.add_dependency "parallel", "~> 1.20"
  spec.add_dependency "require_all", ">= 2", "< 4"

  spec.add_development_dependency "pry", "~> 0.14.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-shopify", "~> 1.0"
  spec.add_development_dependency "solargraph", "~> 0.40.4"
end
