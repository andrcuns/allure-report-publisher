require "open3"

module Publisher
  class AllureError < StandardError; end

  class NoAllureResultsError < StandardError; end

  # Allure report generator
  #
  class ReportGenerator
    include Helpers

    def initialize(results_glob, results_path, report_path)
      @results_glob = results_glob
      @results_path = results_path
      @report_path = report_path
    end

    # Generate allure report
    #
    # @return [void]
    def generate
      aggregate_results
      generate_report
    end

    private

    attr_reader :results_glob, :results_path, :report_path

    # Copy all results files to results directory
    #
    # @return [void]
    def aggregate_results
      results = Dir.glob(results_glob)
      raise(NoAllureResultsError, "Missing allure results") if results.empty?

      FileUtils.cp(results, results_path)
    end

    # Generate allure report
    #
    # @return [void]
    def generate_report
      out, _err, status = Open3.capture3(
        "allure generate --clean --output #{report_path} #{results_path}"
      )
      raise(AllureError, out) unless status.success?
    end
  end
end
