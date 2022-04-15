require "forwardable"

module Publisher
  module Uploaders
    class HistoryNotFoundError < StandardError; end

    # Uploader implementation
    #
    class Uploader
      include Helpers
      extend Forwardable

      EXECUTOR_JSON = "executor.json".freeze
      HISTORY = [
        "categories-trend.json",
        "duration-trend.json",
        "history-trend.json",
        "history.json",
        "retry-trend.json"
      ].freeze

      def initialize(results_glob:, bucket:, update_pr: nil, prefix: nil, copy_latest: false)
        @results_glob = results_glob
        @bucket_name = bucket
        @prefix = prefix
        @update_pr = update_pr
        @copy_latest = (Providers.provider && copy_latest).to_b # copy latest for ci only
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

        report_generator.generate
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
      # @return [Hash<String, String>] uploaded report urls
      def report_urls
        urls = { "Report url" => report_url }
        urls["Latest report url"] = latest_report_url if copy_latest

        urls
      end

      # Executed in PR pipeline
      #
      # @return [Boolean]
      def pr?
        ci_provider&.pr?
      end

      private

      attr_reader :results_glob,
                  :bucket_name,
                  :prefix,
                  :update_pr,
                  :copy_latest

      def_delegators :report_generator, :results_path, :report_path

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

      # Allure report generator
      #
      # @return [Publisher::ReportGenerator]
      def report_generator
        @report_generator ||= ReportGenerator.new(results_glob)
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

      # Report files
      #
      # @return [Array<Pathname>]
      def report_files
        @report_files ||= Pathname
                          .glob("#{report_path}/**/*")
                          .reject(&:directory?)
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

        @ci_provider = Providers.provider&.new(
          report_url: report_url,
          report_path: report_path,
          update_pr: update_pr
        )
      end

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

        File.write("#{results_path}/#{EXECUTOR_JSON}", ci_provider.executor_info.to_json)
      end

      # Run upload commands
      #
      # @return [void]
      def run_uploads
        upload_history unless !run_id || copy_latest
        upload_report
        upload_latest_copy if copy_latest
      end

      # Fetch allure report history
      #
      # @return [void]
      def create_history_dir
        FileUtils.mkdir_p(path(results_path, "history"))
      end
    end
  end
end
