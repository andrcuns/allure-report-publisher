require "forwardable"
require "json"

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

      # Uploader instance
      #
      # @param [Hash] args
      # @option args [Array] :result_paths
      # @option args [String] :bucket
      # @option args [String] :prefix
      # @option args [String] :base_url
      # @option args [String] :copy_latest
      # @option args [String] :report_name
      # @option args [Integer] :parallel
      def initialize(**args)
        @result_paths = args[:result_paths]
        @bucket_name = args[:bucket]
        @prefix = args[:prefix]
        @base_url = args[:base_url]
        @copy_latest = ci_info && args[:copy_latest] # copy latest for ci only
        @report_name = args[:report_name]
        @parallel = args[:parallel]
      end

      # Generate allure report
      #
      # @return [void]
      def generate_report(extra_arguments = [])
        add_history
        add_executor_info

        report_generator.generate(extra_arguments)
      end

      # Upload report to storage provider
      #
      # @return [void]
      def upload
        upload_history unless !run_id || copy_latest
        upload_report
        upload_latest_copy if copy_latest
      end

      # Uploaded report urls
      #
      # @return [Hash<String, String>] uploaded report urls
      def report_urls
        urls = { "Report url" => report_url }
        urls["Latest report url"] = latest_report_url if copy_latest

        urls
      end

      # :nocov:

      # Report url
      #
      # @return [String]
      def report_url
        raise("Not Implemented!")
      end

      # :nocov:

      def_delegator :report_generator, :report_path

      private

      attr_reader :result_paths,
                  :bucket_name,
                  :prefix,
                  :base_url,
                  :copy_latest,
                  :report_name,
                  :parallel

      def_delegator :report_generator, :common_info_path

      # CI info
      #
      # @return [Providers::Info::Base]
      def ci_info
        Providers.info
      end

      # :nocov:

      # Cloud provider client
      #
      # @return [Object]
      def client
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
        @report_generator ||= ReportGenerator.new(result_paths, report_name)
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
        @run_id ||= ci_info&.run_id
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
        return unless ci_info

        json = JSON.pretty_generate(ci_info.executor(report_url))
        log_debug("Saving ci executor info:\n#{json}")
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
