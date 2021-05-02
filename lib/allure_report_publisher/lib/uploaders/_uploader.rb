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

      def initialize(results_glob, bucket, prefix = nil)
        @results_glob = results_glob
        @bucket = bucket
        @prefix = prefix
      end

      # :nocov:

      # Execute allure report generation and upload
      #
      # @return [void]
      def execute(update_pr: false)
        generate_report
        upload_history_and_report
        add_report_url if update_pr
      end

      private

      attr_reader :results_glob, :bucket, :prefix

      # Report url
      #
      # @return [String]
      def report_url
        raise("Not Implemented!")
      end

      # Upload report to s3
      #
      # @return [void]
      def upload_history_and_report
        raise("Not implemented!")
      end

      # Add allure history
      #
      # @return [void]
      def add_history
        log("Adding allure history")
        Helpers::Spinner.spin("adding history", exit_on_error: false) do
          create_history_dir
          yield
        end
      end

      # Add CI executor info
      #
      # @return [void]
      def add_executor_info
        return unless ci_provider

        log("Adding executor info")
        Helpers::Spinner.spin("adding executor") do
          ci_provider.write_executor_info
        end
      end

      # Generate allure report
      #
      # @return [void]
      def generate_report
        add_history
        add_executor_info

        ReportGenerator.new(results_glob, results_dir, report_dir).generate
      end

      # Add allure report url to pull request description
      #
      # @return [void]
      def add_report_url
        return unless ci_provider

        log("Adding allure report link to pr description")
        Helpers::Spinner.spin("adding link", exit_on_error: false) do
          ci_provider.add_report_url
        end
      end
      # :nocov:

      # Get run id
      #
      # @return [String]
      def run_id
        @run_id ||= Providers.provider&.run_id
      end

      # Get CI provider
      #
      # @return [Publisher::Providers::Base]
      def ci_provider
        return @ci_provider if defined?(@ci_provider)

        @ci_provider = Providers.provider&.new(results_dir, report_url)
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
      def full_prefix
        @full_prefix ||= [prefix, run_id].compact.yield_self do |pre|
          break if pre.empty?

          pre.join("/")
        end
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
    end
  end
end
