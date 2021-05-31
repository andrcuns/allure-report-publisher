# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake", "~> 13.0"

group :release do
  gem "git", "~> 1.8"
  gem "semver2", "~> 3.4"
  gem "yard", "~> 0.9.26"
end

group :test do
  gem "allure-rspec", "~> 2.14.0"
  gem "climate_control", "~> 1.0.1"
  gem "rspec", "~> 3.0"
  gem "rubocop", "~> 1.15"
  gem "rubocop-performance", "~> 1.11"
  gem "rubocop-rake", "~> 0.5.1"
  gem "rubocop-rspec", "~> 2.3"
  gem "simplecov", "~> 0.21.2"
  gem "simplecov-console", "~> 0.9.1"
end

group :development do
  gem "pry-byebug", "~> 3.9"
  gem "solargraph", "~> 0.41.0"
end
