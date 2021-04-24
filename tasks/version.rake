require "semver"
require "git"

# Update app version
#
class Version
  include Rake::DSL
  include Publisher::Helpers

  VERSION_FILE = "lib/allure_report_publisher/version.rb".freeze
  GEMFILE = "pkg/allure-report-publisher-#{Publisher::VERSION}.gem".freeze

  # Add version bump task
  #
  def add_version_task
    desc("Bump application version [major, minor, patch]")
    task(:version, [:semver]) do |_task, args|
      new_version = send(args[:semver]).format("%M.%m.%p").to_s

      spin("Updating app version", done_message: "updated to v#{new_version}") do
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
    git = Git.init
    git.add([VERSION_FILE, "Gemfile.lock"])
    git.commit("Update to #{new_version}")
    git.add_tag(new_version.to_s)
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
end

Version.new.tap(&:add_version_task)
