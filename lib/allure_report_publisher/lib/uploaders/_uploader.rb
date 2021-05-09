module Publisher
  module Uploaders
    class HistoryNotFoundError < StandardError; end

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
        @bucket_name = bucket
        @prefix = prefix
        @update_pr = update_pr
        @copy_latest = !!(Providers.provider && copy_latest) # copy latest for ci only
      end

      # Execute allure report generation and upload
      #
      # @return [void]
      def execute
        generate_report
        upload
        add_url_to_pr
      end

      # Generate allure report
      #
      # @return [void]
      def generate_report
        add_history
        add_executor_info

        ReportGenerator.new(results_glob, results_dir, report_dir).generate
      end

      # Upload report to storage provider
      #
      # @return [void]
      def upload
        run_uploads
      end

      # Add allure report url to pull request description
      #
      # @return [void]
      def add_url_to_pr
        return unless update_pr && ci_provider

        ci_provider.add_report_url
      end

      # Uploaded report urls
      #
      # @return [Hash<Symbol, String>]
      def report_urls
        urls = { "Report url" => report_url }
        urls["Latest report url"] = latest_report_url if copy_latest

        urls
      end

      private

      attr_reader :results_glob, :bucket_name, :prefix, :update_pr, :copy_latest

      # :nocov:

      # Cloud provider client
      #
      # @return [Object]
      def client
        raise("Not Implemented!")
      end

      # Report url
      #
      # @return [String]
      def report_url
        raise("Not Implemented!")
      end

      # Latest report url
      #
      # @return [String]
      def latest_report_url
        raise("Not Implemented!")
      end

      # Download allure history
      #
      # @return [void]
      def download_history
        raise("Not implemented!")
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
        create_history_dir
        download_history
      rescue HistoryNotFoundError
        nil
      end

      # Add CI executor info
      #
      # @return [void]
      def add_executor_info
        return unless ci_provider

        ci_provider.write_executor_info
      end

      # Run upload commands
      #
      # @return [void]
      def run_uploads
        upload_history unless !run_id || copy_latest
        upload_report
        upload_latest_copy if copy_latest
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
