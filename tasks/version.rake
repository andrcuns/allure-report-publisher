require "semver"

module Publisher
  # Update app version
  #
  class VersionTask
    include Rake::DSL
    include Publisher::Helpers

    VERSION_FILE = "lib/allure_report_publisher/version.rb".freeze

    def initialize
      add_version_task
    end

    # Add version bump task
    #
    def add_version_task
      desc("Bump application version [major, minor, patch, rc]")
      task(:version, [:semver]) do |_task, args|
        Helpers.pastel(force_color: args[:color])
        new_version = send(args[:semver]).then { |ver| "#{ver.format('%M.%m.%p')}.#{ver.special}" }

        Helpers::Spinner.spin("Updating app version", done_message: "updated to v#{new_version}", debug: true) do
          update_version(new_version)
          update_lock
          commit_and_tag(new_version)
        end
      end
    end

    private

    # Update version file
    #
    # @param [SemVer] new_version
    # @return [void]
    def update_version(new_version)
      u_version = File.read(VERSION_FILE).gsub(Publisher::VERSION, new_version)
      File.write(VERSION_FILE, u_version)
    end

    # Update lock file
    #
    # @return [void]
    def update_lock
      execute_shell("bundle install")
    end

    # Commit updated version file and Gemfile.lock
    #
    # @return [void]
    def commit_and_tag(new_version)
      execute_shell("git add #{VERSION_FILE} Gemfile.lock")
      execute_shell("git commit -m 'Update to v#{new_version}'")
      execute_shell("git tag v#{new_version}")
      execute_shell("git push && git push --tags")
    end

    # Semver of ref from
    #
    # @return [SemVer]
    def semver
      @semver ||= SemVer.parse(Publisher::VERSION)
    end

    # Increase patch version
    #
    # @return [SemVer]
    def patch
      semver.tap { |ver| ver.patch += 1 }
    end

    # Increase minor version
    #
    # @return [SemVer]
    def minor
      semver.tap do |ver|
        ver.minor += 1
        ver.patch = 0
      end
    end

    # Increase major version
    #
    # @return [SemVer]
    def major
      semver.tap do |ver|
        ver.major += 1
        ver.minor = 0
        ver.patch = 0
      end
    end

    # Increase rc version
    #
    # @return [SemVer]
    def rc
      return major.tap { |ver| ver.special = "rc.1" } if semver.special.empty?

      # Increment the rc version
      semver.tap { |ver| ver.special = ver.special.gsub(/\d+/) { |num| num.to_i.next } }
    end
  end
end
