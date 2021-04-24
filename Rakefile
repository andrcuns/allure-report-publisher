# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

require "rubygems/tasks"

Gem::Tasks.new(scm: { tag: false, push: false })

task default: %i[spec rubocop]
