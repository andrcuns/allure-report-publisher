# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake", "~> 13.0"

group :release do
  gem "git", "~> 1.10"
  gem "semver2", "~> 3.4"
  gem "yard", "~> 0.9.27"
end

group :test do
  gem "allure-rspec", "~> 2.15.0"
  gem "climate_control", "~> 1.0.1"
  gem "rspec", "~> 3.0"
  gem "rubocop", "~> 1.24"
  gem "rubocop-performance", "~> 1.13"
  gem "rubocop-rake", "~> 0.6.0"
  gem "rubocop-rspec", "~> 2.7"
  gem "simplecov", "~> 0.21.2"
  gem "simplecov-console", "~> 0.9.1"
end

group :development do
  gem "pry-byebug", "~> 3.9"
  gem "solargraph", "~> 0.44.2"
end
