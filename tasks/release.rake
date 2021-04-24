# Release tasks
#
class Release
  include Rake::DSL
  include Publisher::Helpers

  # Add build task
  #
  def add_build_task
    desc("Build allure-report-publisher")
    task(:build) do
      log("Building #{GEMFILE}")
      FileUtils.mkdir_p("pkg") unless File.exist?("pkg")
      sh("gem build -o #{GEMFILE}")
    end
  end

  # Add release tasks
  #
  def add_release_task
    desc("Build and push allure-report-publisher")
    task(release: :build) do
      log("Pushing gem #{GEMFILE}")
      sh("gem push #{GEMFILE}")
    end
  end
end

Release.new.tap do |release|
  release.add_build_task
  release.add_release_task
end
