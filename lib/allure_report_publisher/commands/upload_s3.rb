module Publisher
  module Commands
    # Upload allure report
    #
    class UploadS3 < Dry::CLI::Command
      include CommonOptions
      include Helpers

      desc "Generate and upload allure report"

      option :result_files_glob, desc: "Allure results files glob. Required: true"
      option :bucket, desc: "Bucket name. Required: true"
      option :prefix, desc: "Optional prefix for report path. Required: false"

      example [
        "--result-files-glob='path/to/allure-result/**/*' --bucket=my-bucket",
        "--result-files-glob='path/to/allure-result/**/*' --bucket=my-bucket --project=my-project/prs"
      ]

      def call(**args)
        validate_args(args)
        Helpers.pastel(force_color: args[:color])

        Uploaders::S3.new(
          args[:result_files_glob],
          args[:bucket],
          args[:prefix]
        ).execute
      end

      private

      # Validate required args
      #
      # @param [Hash] args
      # @return [void]
      def validate_args(args)
        error("Missing argument --result-files-glob!") unless args[:result_files_glob]
        error("Missing argument --bucket!") unless args[:bucket]
      end
    end
  end
end
