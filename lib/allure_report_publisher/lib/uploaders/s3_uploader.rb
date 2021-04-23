require "aws-sdk-s3"

module Allure
  module Publisher
    module Uploaders
      class S3 < Uploader
        def execute
          generate_report
          upload_history_and_report
        end

        private

        # S3 client
        #
        # @return [Aws::S3::Client]
        def s3
          @s3 ||= Aws::S3::Client.new
        end

        # Report url
        #
        # @return [String]
        def report_url
          @report_url ||= ["http://#{bucket}.s3.amazonaws.com", prefix, "index.html"].compact.join("/")
        end

        # Fetch allure history
        #
        # @return [void]
        def fetch_history
          super

          log("Fetching allure history")
          spin("fetching history") do
            HISTORY.each do |file|
              s3.get_object(
                response_target: path(results_dir, "history", file),
                key: key(project, "history", file),
                bucket: bucket,
              )
            end
          end
        end

        # Upload report to s3
        #
        # @return [void]
        def upload_history_and_report
          log("\nUploading report to s3")
          spin("uploading report", done_message: "done. #{report_url}") do
            upload_history
            upload_report
          end
        end

        # Upload allure history
        #
        # @return [void]
        def upload_history
          return unless run_id

          upload_to_s3(report_files.select { |file| file.fnmatch?("*/history/*") }, project)
        end

        def upload_report
          upload_to_s3(report_files)
        end

        # Upload files to s3
        #
        # @param [Array<Pathname>] files
        # @param [String] key_prefix
        # @return [Array<Hash>]
        def upload_to_s3(files, key_prefix = prefix)
          args = files.map do |file|
            {
              body: File.new(file),
              bucket: bucket,
              key: key(key_prefix, file.relative_path_from(report_dir)),
            }
          end

          Parallel.each(args) { |obj| s3.put_object(obj) }
        end

        # Fabricate key for s3 object
        #
        # @param [String] *args
        # @return [String]
        def key(*args)
          args.compact.join("/")
        end
      end
    end
  end
end
