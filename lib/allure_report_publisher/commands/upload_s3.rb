module Publisher
  module Commands
    # Upload allure report
    #
    class UploadS3 < Dry::CLI::Command
      include CommonOptions
      include Helpers

      desc "Generate and upload allure report"

      option :results_glob, desc: "Allure results files glob. Required: true"
      option :bucket, desc: "Bucket name. Required: true"
      option :prefix, desc: "Optional prefix for report path. Required: false"

      example [
        "--results-glob='path/to/allure-result/**/*' --bucket=my-bucket",
        "--results-glob='path/to/allure-result/**/*' --bucket=my-bucket --project=my-project/prs"
      ]

      def call(**args)
        validate_args(args)
        Helpers.pastel(force_color: args[:color])

        Uploaders::S3
          .new(**args.slice(:results_glob, :bucket, :prefix, :copy_latest, :update_pr))
          .execute
      end

      private

      # Validate required args
      #
      # @param [Hash] args
      # @return [void]
      def validate_args(args)
        error("Missing argument --results-glob!") unless args[:results_glob]
        error("Missing argument --bucket!") unless args[:bucket]
      end
    end
  end
end
