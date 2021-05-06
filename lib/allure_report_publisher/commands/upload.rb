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
             desc: "Allure results files glob. Required: true"
      option :bucket,
             desc: "Bucket name. Required: true"
      option :prefix,
             desc: "Optional prefix for report path. Required: false"
      option :update_pr,
             type: :boolean,
             default: false,
             desc: "Update pull request description with url to allure report"
      option :copy_latest,
             type: :boolean,
             default: false,
             desc: "Keep copy of latest report at base prefix path"
      option :color,
             type: :boolean,
             default: false,
             desc: "Toggle color output"

      example [
        "s3 --results-glob='path/to/allure-result/**/*' --bucket=my-bucket",
        "gcs --results-glob='path/to/allure-result/**/*' --bucket=my-bucket --prefix=my-project/prs"
      ]

      def call(**args)
        validate_args(args)
        validate_result_files(args[:results_glob])
        Helpers.pastel(force_color: args[:color] || nil)

        uploaders(args[:type])
          .new(**args.slice(:results_glob, :bucket, :prefix, :copy_latest, :update_pr))
          .execute
      end

      private

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
      # @param [Hash] args
      # @return [void]
      def validate_args(args)
        error("Missing argument --results-glob!") unless args[:results_glob]
        error("Missing argument --bucket!") unless args[:bucket]
      end

      # Check if allure results present
      #
      # @param [String] results_glob
      # @return [void]
      def validate_result_files(results_glob)
        Dir.glob(results_glob).empty? && error("Glob '#{results_glob}' did not match any files!")
      end
    end
  end
end
