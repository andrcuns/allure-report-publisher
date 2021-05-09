require "open3"

module Publisher
  class AllureError < StandardError; end

  class NoAllureResultsError < StandardError; end

  # Allure report generator
  #
  class ReportGenerator
    include Helpers

    def initialize(results_glob, results_dir, report_dir)
      @results_glob = results_glob
      @results_dir = results_dir
      @report_dir = report_dir
    end

    # Generate allure report
    #
    # @return [void]
    def generate
      aggregate_results
      generate_report
    end

    private

    attr_reader :results_glob, :results_dir, :report_dir

    # Copy all results files to results directory
    #
    # @return [void]
    def aggregate_results
      results = Dir.glob(results_glob)
      raise("Missing allure results") if results.empty?

      FileUtils.cp(results, results_dir)
    end

    # Generate allure report
    #
    # @return [void]
    def generate_report
      out, _err, status = Open3.capture3(
        "allure generate --clean --output #{report_dir} #{results_dir}"
      )
      raise(out) unless status.success?
    end
  end
end
