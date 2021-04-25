module Publisher
  # Release tasks
  #
  class ReleaseTask
    include Rake::DSL
    include Publisher::Helpers

    GEMFILE = "pkg/allure-report-publisher-#{Publisher::VERSION}.gem".freeze

    def initialize
      add_build_task
      add_release_task
    end

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
end
