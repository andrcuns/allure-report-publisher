require "forwardable"
require "json"

module Publisher
  module Uploaders
    class HistoryNotFoundError < StandardError; end

    PARALLEL_THREADS = 8

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

      # Uploader instance
      #
      # @param [Hash] args
      # @option args [Array] :result_paths
      # @option args [String] :bucket
      # @option args [String] :prefix
      # @option args [String] :base_url
      # @option args [Boolean] :update_pr
      # @option args [String] :summary_type
      # @option args [Symbol] :summary_table_type
      # @option args [Boolean] :collapse_summary
      # @option args [Boolean] :unresolved_discussion_on_failure
      # @option args [String] :copy_latest
      def initialize(**args)
        @result_paths = args[:result_paths]
        @bucket_name = args[:bucket]
        @prefix = args[:prefix]
        @base_url = args[:base_url]
        @update_pr = args[:update_pr]
        @summary_type = args[:summary_type]
        @summary_table_type = args[:summary_table_type]
        @copy_latest = Providers.provider && args[:copy_latest] # copy latest for ci only
        @collapse_summary = args[:collapse_summary]
        @unresolved_discussion_on_failure = args[:unresolved_discussion_on_failure]
      end

      # Execute allure report generation and upload
      #
      # @return [void]
      def execute
        generate_report
        upload
        add_result_summary
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
        upload_history unless !run_id || copy_latest
        upload_report
        upload_latest_copy if copy_latest
      end

      # Add allure report url to pull request description
      #
      # @return [void]
      def add_result_summary
        return unless update_pr && ci_provider

        log_debug("Adding test result summary")
        ci_provider.add_result_summary
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

      attr_reader :result_paths,
                  :bucket_name,
                  :prefix,
                  :base_url,
                  :update_pr,
                  :copy_latest,
                  :summary_type,
                  :collapse_summary,
                  :summary_table_type,
                  :unresolved_discussion_on_failure

      def_delegators :report_generator, :common_info_path, :report_path

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
        @report_generator ||= ReportGenerator.new(result_paths)
      end

      # Report path prefix
      #
      # @return [String]
      def full_prefix
        @full_prefix ||= [prefix, run_id].compact.then do |pre|
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
          update_pr: update_pr,
          summary_type: summary_type,
          summary_table_type: summary_table_type,
          collapse_summary: collapse_summary,
          unresolved_discussion_on_failure: unresolved_discussion_on_failure
        )
      end

      # Add allure history
      #
      # @return [void]
      def add_history
        create_history_dir
        download_history
      rescue HistoryNotFoundError => e
        log_debug(e.message)
        nil
      end

      # Add CI executor info
      #
      # @return [void]
      def add_executor_info
        return unless ci_provider

        json = ci_provider.executor_info.to_json
        log_debug("Saving ci executor info:\n#{JSON.pretty_generate(ci_provider.executor_info)}")
        # allure-report will fail to pick up reportUrl in history tab if executor.json is not present alongside results
        [common_info_path, *result_paths].each do |path|
          file = File.join(path, EXECUTOR_JSON)
          next log_debug("Skipping '#{file}', executor info already exists") if File.exist?(file)

          File.write(File.join(path, EXECUTOR_JSON), json)
          log_debug("Saved ci executor info to '#{file}'")
        end
      end

      # Fetch allure report history
      #
      # @return [void]
      def create_history_dir
        path = FileUtils.mkdir_p(path(common_info_path, "history"))
        log_debug("Created tmp folder for history data: '#{path.first}'")
      end
    end
  end
end
