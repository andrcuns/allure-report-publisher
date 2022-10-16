require "open3"

module Publisher
  class AllureError < StandardError; end

  class NoAllureResultsError < StandardError; end

  # Allure report generator
  #
  class ReportGenerator
    include Helpers

    def initialize(results_glob)
      @results_glob = results_glob
    end

    # Generate allure report
    #
    # @return [void]
    def generate
      create_common_path
      create_report_path

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
      @report_path ||= Dir.mktmpdir("allure-report").tap do |path|
        log_debug("Created tmp folder for allure report: '#{path}'")
      end
    end
    alias create_report_path report_path

    private

    attr_reader :results_glob

    # Return all allure results paths from glob
    #
    # @return [String]
    def result_paths
      @result_paths ||= begin
        paths = Dir.glob(results_glob)
        raise(NoAllureResultsError, "Missing allure results") if paths.empty?

        paths.join(" ")
      end
    end

    # Generate allure report
    #
    # @return [void]
    def generate_report
      log_debug("Generating allure report from following paths: #{result_paths}")
      cmd = "allure generate --clean --output #{report_path} #{common_info_path} #{result_paths}"
      out = execute_shell(cmd)
      log_debug("Generated allure report, output: #{out}")
    rescue StandardError => e
      raise(AllureError, e.message)
    end
  end
end
