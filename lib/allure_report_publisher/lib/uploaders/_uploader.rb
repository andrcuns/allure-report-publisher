module Publisher
  module Uploaders
    # Uploader implementation
    #
    class Uploader
      include Helpers

      HISTORY = [
        "categories-trend.json",
        "duration-trend.json",
        "history-trend.json",
        "history.json",
        "retry-trend.json"
      ].freeze

      def initialize(results_glob, bucket, project = nil)
        @results_glob = results_glob
        @bucket = bucket
        @project = project
      end

      # Execute allure report generation and upload
      #
      # @return [void]
      def execute
        raise(StandardError, "Not Implemented!")
      end

      private

      attr_reader :results_glob, :bucket, :project

      # Report url
      #
      # @return [String]
      def report_url
        raise(StandardError, "Not Implemented!")
      end

      # Fetch allure report history
      #
      # @return [void]
      def create_history_dir
        FileUtils.mkdir_p(path(results_dir, "history"))
      end

      # Report path prefix
      #
      # @return [String]
      def prefix
        @prefix ||= [project, run_id].compact.yield_self do |pre|
          break if pre.empty?

          pre.join("/")
        end
      end

      # Run ID
      #
      # @return [String]
      def run_id
        @run_id ||= ENV["RUN_ID"]
      end

      # Aggregated results directory
      #
      # @return [String]
      def results_dir
        @results_dir ||= Dir.mktmpdir("allure-results")
      end

      # Allure report directory
      #
      # @return [String]
      def report_dir
        @report_dir ||= Dir.mktmpdir("allure-report")
      end

      # Report files
      #
      # @return [Array<Pathname>]
      def report_files
        @report_files ||= Pathname
                          .glob("#{report_dir}/**/*")
                          .reject(&:directory?)
      end

      # Generate allure report
      #
      # @return [void]
      def generate_report
        fetch_history if run_id

        ReportGenerator.new(results_glob, results_dir, report_dir).generate
      end
    end
  end
end
