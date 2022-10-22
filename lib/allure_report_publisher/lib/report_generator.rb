require "open3"

module Publisher
  class AllureError < StandardError; end

  class NoAllureResultsError < StandardError; end

  # Allure report generator
  #
  class ReportGenerator
    include Helpers

    def initialize(result_paths)
      @result_paths = result_paths.join(" ")
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

    # Generate allure report
    #
    # @return [void]
    def generate_report
      log_debug("Generating allure report")
      cmd = "allure generate --clean --output #{report_path} #{common_info_path} #{result_paths}"
      out = execute_shell(cmd)
      log_debug("Generated allure report. #{out}")
    rescue StandardError => e
      raise(AllureError, e.message)
    end
  end
end
