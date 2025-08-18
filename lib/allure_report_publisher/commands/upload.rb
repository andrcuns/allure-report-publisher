require "uri"

module Publisher
  module Commands
    # Upload allure report
    #
    class Upload < Dry::CLI::Command
      include Helpers

      STORAGE_PROVIDERS = %w[gcs s3 gitlab-artifacts].freeze

      desc "Generate and upload allure report"

      argument :type,
               type: :string,
               required: true,
               values: STORAGE_PROVIDERS,
               desc: "Cloud storage type"

      # rubocop:disable Layout/LineLength
      option :results_glob,
             desc: "Glob pattern to return allure results directories. Required: true"
      option :bucket,
             desc: "Bucket name. Required: true (gcs|s3), false (gitlab-artifacts)"
      option :output,
             desc: "Output directory for the report. Required: false. Defaults to 'allure-report' for gitlab-artifacts and random temporary directory for cloud based storage"
      option :prefix,
             desc: "Optional prefix for report path. Required: false. Ignored for gitlab-artifacts"
      option :update_pr,
             type: :string,
             desc: "Add report url to PR via comment or description update. Required: false",
             values: %w[comment description actions]
      option :report_title,
             type: :string,
             default: "Allure Report",
             desc: "Title for url section in PR comment/description. Required: false"
      option :report_name,
             type: :string,
             desc: "Custom report name in final Allure report. Required: false"
      option :summary,
             type: :string,
             desc: "Additionally add summary table to PR comment or description. Required: false",
             default: Publisher::Helpers::Summary::TOTAL,
             values: [
               Publisher::Helpers::Summary::BEHAVIORS,
               Publisher::Helpers::Summary::SUITES,
               Publisher::Helpers::Summary::PACKAGES,
               Publisher::Helpers::Summary::TOTAL
             ]
      option :summary_table_type,
             type: :string,
             desc: "Summary table type. Required: false",
             default: Publisher::Helpers::Summary::ASCII,
             values: [
               Publisher::Helpers::Summary::ASCII,
               Publisher::Helpers::Summary::MARKDOWN
             ]
      option :base_url,
             type: :string,
             desc: "Use custom base url instead of default cloud provider one. Required: false. For gitlab-artifacts, replaces default gitlab.io pages hostname"
      option :parallel,
             type: :integer,
             desc: "Number of parallel threads to use for report file upload to cloud storage. Required: false",
             default: 8
      option :flaky_warning_status,
             type: :boolean,
             default: false,
             desc: "Mark run with a '!' status in PR comment/description if report contains flaky tests"
      option :collapse_summary,
             type: :boolean,
             default: false,
             desc: "Create summary as a collapsible section"
      option :copy_latest,
             type: :boolean,
             default: false,
             desc: "Keep copy of latest report at base prefix path. Ignored for gitlab-artifacts"
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
      # rubocop:enable Layout/LineLength

      example [
        "s3 --results-glob='path/to/allure-results' --bucket=my-bucket",
        "gcs --results-glob='paths/to/**/allure-results' --bucket=my-bucket --prefix=my-project/prs",
        "gitlab-artifacts --results-glob='paths/to/**/allure-results'"
      ]

      def call(args: [], **arguments)
        Helpers.pastel(force_color: arguments[:color])
        @args = arguments

        validate_args!
        scan_results_paths

        generate_report(args)
        upload_report
        return unless arguments[:update_pr] && Providers.info&.pr?

        add_report_urls
      rescue StandardError => e
        handle_error(e)
      end

      private

      attr_reader :args

      # Report output path
      #
      # @return [String] output path
      def output
        @output ||= args[:output].then do |path|
          next path if path && !path.empty?

          gitlab_artifacts? ? "allure-report" : File.join(Dir.tmpdir, "allure-report-#{Time.now.to_i}")
        end
      end

      # Uploader instance
      #
      # @return [Publisher::Uploaders::Uploader]
      def uploader
        @uploader ||= uploaders(args[:type]).new(
          result_paths: @result_paths,
          parallel: parallel_threads,
          output: output,
          **args.slice(:bucket, :prefix, :base_url, :copy_latest, :report_name)
        )
      end

      # CI provider instance
      #
      # @return [Publisher::Providers::Base]
      def ci_provider
        @ci_provider = Providers.provider&.new(
          report_url: uploader.report_url,
          report_path: output,
          summary_type: args[:summary],
          **args.slice(
            :update_pr,
            :collapse_summary,
            :flaky_warning_status,
            :summary_table_type,
            :report_title
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
          "gcs" => Uploaders::GCS,
          "gitlab-artifacts" => Uploaders::GitlabArtifacts
        }.fetch(uploader)
      end

      # Validate required args
      #
      # @return [void]
      def validate_args!
        validate_base_args!
        validate_base_url!
        cast_parallel_threads_arg!
      end

      # Check base arguments
      #
      # @return [void]
      def validate_base_args!
        unless STORAGE_PROVIDERS.include?(args[:type])
          error("Unsupported storage type! Supported types are: #{STORAGE_PROVIDERS.join(', ')}")
        end

        error("Missing argument --results-glob!") unless args[:results_glob]
        error("Missing argument --bucket!") unless gitlab_artifacts? || args[:bucket]
      end

      # Check base URL is a valid URI
      #
      # @return [void]
      def validate_base_url!
        return unless args[:base_url]

        URI.parse(args[:base_url])
      rescue URI::InvalidURIError
        error("Invalid --base-url value!")
      end

      # Parallel threads
      #
      # @return [Integer]
      def parallel_threads
        @parallel_threads ||= Integer(args[:parallel]).tap do |threads|
          raise ArgumentError if threads < 1
        end
      rescue ArgumentError
        error("Invalid --parallel value, must be a positive number!")
      end
      alias cast_parallel_threads_arg! parallel_threads

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

      # Gitlab artifacts store
      #
      # @return [Boolean] true if gitlab artifacts store is used
      def gitlab_artifacts?
        args[:type] == "gitlab-artifacts"
      end

      # Generate allure report
      #
      # @param [Array<String>] extra_args
      # @return [void]
      def generate_report(extra_args)
        log("Generating allure report")
        Spinner.spin("generating", debug: args[:debug]) { uploader.generate_report(extra_args) }
      end

      # Upload report to cloud storage
      #
      # @return [void]
      def upload_report
        log("Uploading allure report to #{args[:type]}")
        # gitlab-artifacts by default will raise error with info about upload using artifacts
        spinner_args = {
          debug: args[:debug],
          exit_on_error: !gitlab_artifacts?,
          failed_message: gitlab_artifacts? ? "skipped" : nil
        }.compact
        Spinner.spin("uploading", **spinner_args) { uploader.upload }
        uploader.report_urls.each { |k, v| log("#{k}: #{v}", :green) }
      end

      # Add report results to pr/mr
      #
      # @return [void]
      def add_report_urls
        log("Adding reports urls")
        Spinner.spin("updating", exit_on_error: false, debug: args[:debug]) { ci_provider.add_result_summary }
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
