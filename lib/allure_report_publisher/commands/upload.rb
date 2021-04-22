module Allure
  module Publisher
    module Commands
      # Upload allure report
      #
      class Upload < Dry::CLI::Command
        include Helpers

        EXECUTOR_JSON = "executor.json".freeze
        ALLURE_REPORT_DIR = "allure-report".freeze

        desc "Generate and upload allure report"

        option :result_files_glob, desc: "Allure results files glob. Required: true"
        option :bucket, desc: "Bucket name. Required: true"
        option :project, desc: "Project name for multiple reports inside single bucket. Required: false"

        example [
          "--result-files-glob='path/to/allure-result/**/*' --bucket=my-bucket",
        ]

        def call(**args)
          validate_args(args)

          Uploaders::S3.new(
            args[:result_files_glob],
            args[:bucket],
            args[:project]
          ).execute
        end

        private

        # Validate required args
        #
        # @param [Hash] args
        # @return [void]
        def validate_args(args)
          unless args[:result_files_glob]
            log("Missing argument --result-files-glob", "red")
            exit(1)
          end

          unless args[:bucket]
            log("Missing argument --bucket", "red")
            exit(1)
          end
        end
      end
    end
  end
end
