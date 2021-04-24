require "rake"

require_relative "../lib/allure_report_publisher"

# Release tasks
#
class ReleaseTasks
  include Rake::DSL
  include Publisher::Helpers

  def build
    desc("Build allure-report-publisher")
    task(:build) do
      log("Building #{gemfile}")
      FileUtils.mkdir_p("pkg")
      sh("gem build -o #{gemfile}")
    end
  end

  def release
    desc("Build and push allure-report-publisher")
    task(release: :build) do
      log("Pushing gem #{gemfile}")
      sh("gem push #{gemfile}")
    end
  end

  private

  def gemfile
    @gemfile ||= "pkg/allure-report-publisher-#{Publisher::VERSION}.gem"
  end
end

ReleaseTasks.new.tap do |tasks|
  tasks.build
  tasks.release
end
