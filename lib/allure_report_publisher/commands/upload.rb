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
      option :summary,
             type: :string,
             desc: "Additionally add summary table to PR comment or description. Required: false",
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

      example [
        "s3 --results-glob='path/to/allure-results' --bucket=my-bucket",
        "gcs --results-glob='paths/to/**/allure-results' --bucket=my-bucket --prefix=my-project/prs"
      ]

      def call(**args)
        Helpers.pastel(force_color: args[:color])
        @args = args

        validate_args
        validate_result_files

        log("Generating allure report")
        Spinner.spin("generating") { uploader.generate_report }

        log("Uploading allure report to #{args[:type]}")
        Spinner.spin("uploading") { uploader.upload }
        uploader.report_urls.each { |k, v| log("#{k}: #{v}", :green) }
        return unless args[:update_pr] && uploader.pr?

        log("Adding reports urls")
        Spinner.spin("updating", exit_on_error: false) { uploader.add_result_summary }
      end

      private

      attr_reader :args

      # Uploader instance
      #
      # @return [Publisher::Uploaders::Uploader]
      def uploader
        @uploader ||= uploaders(args[:type]).new(
          summary_type: args[:summary],
          **args.slice(
            :results_glob,
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

      # Check if allure results present
      #
      # @param [String] results_glob
      # @return [void]
      def validate_result_files
        results_glob = args[:results_glob]
        ignore = args[:ignore_missing_results]
        return unless Dir.glob(results_glob).empty?

        log("Glob '#{results_glob}' did not match any files!", ignore ? :yellow : :red)
        exit(ignore ? 0 : 1)
      end
    end
  end
end
