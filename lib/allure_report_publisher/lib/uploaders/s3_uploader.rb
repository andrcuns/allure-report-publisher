require "aws-sdk-s3"

module Publisher
  module Uploaders
    # Report upload to AWS S3 bucket
    #
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
        @report_url ||= ["http://#{bucket}.s3.amazonaws.com", path_prefix, "index.html"].compact.join("/")
      end

      # Add allure history
      #
      # @return [void]
      def add_history
        super do
          HISTORY.each do |file|
            s3.get_object(
              response_target: path(results_dir, "history", file),
              key: key(prefix, "history", file),
              bucket: bucket
            )
          end
        rescue Aws::S3::Errors::NoSuchKey
          raise("Allure history from previous runs not found!")
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
        upload_to_s3(report_files.select { |file| file.fnmatch?("*/history/*") }, prefix)
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
            key: key(key_prefix, file.relative_path_from(report_dir))
          }
        end

        Parallel.each(args, in_threads: 8) { |obj| s3.put_object(obj) }
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
