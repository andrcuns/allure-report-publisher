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
      generate_report
    end

    # Common path for history and executor info
    #
    # @return [String]
    def common_info_path
      @common_info_path ||= Dir.mktmpdir("allure-results")
    end

    # Allure report directory
    #
    # @return [String]
    def report_path
      @report_path ||= Dir.mktmpdir("allure-report")
    end

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
      out, _err, status = Open3.capture3(
        "allure generate --clean --output #{report_path} #{common_info_path} #{result_paths}"
      )
      raise(AllureError, out) unless status.success?
    end
  end
end
