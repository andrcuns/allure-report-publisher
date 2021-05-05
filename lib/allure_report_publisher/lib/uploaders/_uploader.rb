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

      def initialize(results_glob:, bucket:, update_pr: false, prefix: nil, copy_latest: false)
        @results_glob = results_glob
        @bucket = bucket
        @prefix = prefix
        @update_pr = update_pr
        @copy_latest = Providers.provider && copy_latest # copy latest for ci only
      end

      # :nocov:

      # Execute allure report generation and upload
      #
      # @return [void]
      def execute
        check_client_configured

        generate
        upload
        add_url_to_pr
      rescue StandardError => e
        error(e.message)
      end

      private

      attr_reader :results_glob, :bucket, :prefix, :update_pr, :copy_latest

      # Validate if client is properly configured
      # and raise error if it is not
      #
      # @return [void]
      def check_client_configured
        raise("Not Implemented!")
      end

      # Report url
      #
      # @return [String]
      def report_url
        raise("Not Implemented!")
      end

      # Upload history to s3
      #
      # @return [void]
      def upload_history
        raise("Not implemented!")
      end

      # Upload report to s3
      #
      # @return [void]
      def upload_report
        raise("Not implemented!")
      end

      # Upload copy of latest run
      #
      # @return [void]
      def upload_latest_copy
        raise("Not implemented!")
      end
      # :nocov:

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
      def generate
        add_history
        add_executor_info

        ReportGenerator.new(results_glob, results_dir, report_dir).generate
      end

      # Upload report to storage provider
      #
      # @return [void]
      def upload
        log("Uploading report")
        Helpers::Spinner.spin("uploading report") { run_uploads }
        log("Run report: #{report_url}", :green)
        log("Latest report: #{latest_report_url}", :green) if copy_latest
      end

      # Run upload commands
      #
      # @return [void]
      def run_uploads
        upload_history unless copy_latest # latest report will add a common history folder
        upload_report
        upload_latest_copy if copy_latest
      end

      # Add allure report url to pull request description
      #
      # @return [void]
      def add_url_to_pr
        return unless update_pr && ci_provider

        log("Adding allure report link to pr description")
        Helpers::Spinner.spin("adding link", exit_on_error: false) do
          ci_provider.add_report_url
        end
      end

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
