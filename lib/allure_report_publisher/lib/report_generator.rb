require "open3"

module Publisher
  class AllureError < StandardError; end

  class NoAllureResultsError < StandardError; end

  # Allure report generator
  #
  class ReportGenerator
    include Helpers

    def initialize(result_paths, report_name)
      @result_paths = result_paths.join(" ")
      @report_name = report_name
    end

    # Generate allure report
    #
    # @return [void]
    def generate
      create_common_path

      generate_report
    end

    # Common path for history and executor info
    #
    # @return [String]
    def common_info_path
      @common_info_path ||= Dir.mktmpdir("allure-results").tap do |path|
        log_debug("Created tmp folder for common data: '#{path}'")
      end
    end
    alias create_common_path common_info_path

    # Allure report directory
    #
    # @return [String]
    def report_path
      @report_path ||= File.join(Dir.tmpdir, "allure-report-#{Time.now.to_i}")
    end

    private

    # @return [String] result paths string
    attr_reader :result_paths
    # @return [String] custom report name
    attr_reader :report_name

    # Generate allure report
    #
    # @return [void]
    def generate_report
      log_debug("Generating allure report")
      cmd = ["allure generate --clean"]
      cmd << "--report-name #{report_name}" if report_name
      cmd << "--output #{report_path} #{common_info_path} #{result_paths}"
      out = execute_shell(cmd.join(" "))
      log_debug("Generated allure report. #{out}".strip)

      deduplicate_executors
    rescue StandardError => e
      raise(AllureError, e.message)
    end

    # Remove duplicate entries from executors widget
    # This is a workaround for making history work with multiple result paths
    # allure-report requires executors.json in every results folder but it will create duplicate entries
    # in executors widget of the final report
    #
    # @return [void]
    def deduplicate_executors
      executors_file = File.join(report_path, "widgets", "executors.json")
      executors_json = JSON.parse(File.read(executors_file)).uniq

      log_debug("Removing duplicate entries in '#{executors_file}'")
      File.write(executors_file, JSON.generate(executors_json))
    end
  end
end
