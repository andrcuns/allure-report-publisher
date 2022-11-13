module Publisher
  module Commands
    # Upload allure report
    #
    class Upload < Dry::CLI::Command
      include Helpers

      desc "Generate and upload allure report"

      argument :type,
               type: :string,
               required: true,
               values: %w[s3 gcs],
               desc: "Cloud storage type"

      option :results_glob,
             desc: "Glob pattern to return allure results directories. Required: true"
      option :bucket,
             desc: "Bucket name. Required: true"
      option :prefix,
             desc: "Optional prefix for report path. Required: false"
      option :update_pr,
             type: :string,
             desc: "Add report url to PR via comment or description update. Required: false",
             values: %w[comment description actions]
      option :results,
             type: :string,
             desc: <<~DSC.strip,
               Additionally add test result summary or full report to pr description, comment or github actions step summay. Required: false
             DSC
             values: [
               Publisher::Helpers::TestResults::BEHAVIORS,
               Publisher::Helpers::TestResults::SUITES,
               Publisher::Helpers::TestResults::PACKAGES,
               Publisher::Helpers::TestResults::TOTAL,
               Publisher::Helpers::TestResults::FULL_REPORT
             ]
      option :summary_table_type,
             type: :string,
             desc: "Summary table type. Required: false",
             default: Publisher::Helpers::TestResults::ASCII,
             values: [
               Publisher::Helpers::TestResults::ASCII,
               Publisher::Helpers::TestResults::MARKDOWN
             ]
      option :collapse_summary,
             type: :boolean,
             default: false,
             desc: "Create summary as a collapsable section"
      option :copy_latest,
             type: :boolean,
             default: false,
             desc: "Keep copy of latest report at base prefix path"
      option :color,
             type: :boolean,
             desc: "Force color output"
      option :ignore_missing_results,
             type: :boolean,
             default: false,
             desc: "Ignore missing allure results"
      option :debug,
             type: :boolean,
             default: false,
             desc: "Print additional debug output"

      example [
        "s3 --results-glob='path/to/allure-results' --bucket=my-bucket",
        "gcs --results-glob='paths/to/**/allure-results' --bucket=my-bucket --prefix=my-project/prs"
      ]

      def call(**args)
        Helpers.pastel(force_color: args[:color])
        @args = args

        validate_args
        scan_results_paths

        generate_report
        upload_report
        return unless args[:update_pr] && uploader.pr?

        add_report_urls
      rescue StandardError => e
        handle_error(e)
      end

      private

      attr_reader :args

      # Uploader instance
      #
      # @return [Publisher::Uploaders::Uploader]
      def uploader
        @uploader ||= uploaders(args[:type]).new(
          summary_type: args[:results],
          result_paths: @result_paths,
          **args.slice(
            :bucket,
            :prefix,
            :copy_latest,
            :update_pr,
            :collapse_summary,
            :summary_table_type
          )
        )
      end

      # Uploader class
      #
      # @param [String] uploader
      # @return [Publisher::Uploaders::Uploader]
      def uploaders(uploader)
        {
          "s3" => Uploaders::S3,
          "gcs" => Uploaders::GCS
        }[uploader]
      end

      # Validate required args
      #
      # @return [void]
      def validate_args
        error("Missing argument --results-glob!") unless args[:results_glob]
        error("Missing argument --bucket!") unless args[:bucket]
      end

      # Scan for allure results paths
      #
      # @param [String] results_glob
      # @return [void]
      def scan_results_paths
        results_glob = args[:results_glob]
        ignore = args[:ignore_missing_results]
        @result_paths = Dir.glob(results_glob)
        log_debug("Glob '#{results_glob}' found #{@result_paths.size} paths")
        return unless @result_paths.empty?

        log("Glob '#{results_glob}' did not match any paths!", ignore ? :yellow : :red)
        exit(ignore ? 0 : 1)
      end

      # Generate allure report
      #
      # @return [void]
      def generate_report
        log("Generating allure report")
        Spinner.spin("generating", debug: args[:debug]) { uploader.generate_report }
      end

      # Upload report to cloud storage
      #
      # @return [void]
      def upload_report
        log("Uploading allure report to #{args[:type]}")
        Spinner.spin("uploading", debug: args[:debug]) { uploader.upload }
        uploader.report_urls.each { |k, v| log("#{k}: #{v}", :green) }
      end

      # Add report results to pr/mr
      #
      # @return [void]
      def add_report_urls
        log("Adding reports urls")
        Spinner.spin("updating", exit_on_error: false, debug: args[:debug]) { uploader.add_result_summary }
      end

      # Handle error during upload command
      #
      # @param [StandardError] error
      # @return [void]
      def handle_error(error)
        exit(1) if error.is_a?(Spinner::Failure)
        error(error)
      end
    end
  end
end
