require "aws-sdk-s3"
require "mini_mime"

module Publisher
  module Uploaders
    # Report upload to AWS S3 bucket
    #
    class S3 < Uploader
      private

      # S3 client
      #
      # @return [Aws::S3::Client]
      def client
        @client ||= Aws::S3::Client.new(client_args)
      rescue Aws::Sigv4::Errors::MissingCredentialsError
        raise(<<~MSG.strip)
          missing aws credentials, provide credentials with one of the following options:
            - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
            - ~/.aws/credentials file
        MSG
      end

      def client_args
        @client_args ||= {
          region: ENV["AWS_REGION"] || "us-east-1",
          force_path_style: ENV["AWS_FORCE_PATH_STYLE"] == "true",
          endpoint: ENV["AWS_ENDPOINT"]
        }.compact
      end

      # Report url
      #
      # @return [String]
      def report_url
        @report_url ||= url(full_prefix)
      end

      # Latest report url
      #
      # @return [String]
      def latest_report_url
        @latest_report_url ||= url(prefix)
      end

      # Add allure history
      #
      # @return [void]
      def download_history
        HISTORY.each do |file|
          client.get_object(
            response_target: path(results_path, "history", file),
            key: key(prefix, "history", file),
            bucket: bucket_name
          )
        end
      rescue Aws::S3::Errors::NoSuchKey
        raise(HistoryNotFoundError, "Allure history from previous runs not found!")
      end

      # Upload allure history
      #
      # @return [void]
      def upload_history
        upload_to_s3(report_files.select { |file| file.fnmatch?("*/history/*") }, prefix)
      end

      # Upload allure report
      #
      # @return [void]
      def upload_report
        upload_to_s3(report_files, full_prefix)
      end

      # Upload copy of latest run
      #
      # @return [void]
      def upload_latest_copy
        upload_to_s3(report_files, prefix, cache_control: 60)
      end

      # Upload files to s3
      #
      # @param [Array<Pathname>] files
      # @param [String] key_prefix
      # @return [Array<Hash>]
      def upload_to_s3(files, key_prefix, cache_control: 3600)
        args = files.map do |file|
          {
            body: File.new(file),
            bucket: bucket_name,
            key: key(key_prefix, file.relative_path_from(report_path)),
            content_type: MiniMime.lookup_by_filename(file).content_type,
            cache_control: "max-age=#{cache_control}"
          }
        end

        Parallel.each(args, in_threads: 8) { |obj| client.put_object(obj) }
      end

      # Fabricate key for s3 object
      #
      # @param [String] *args
      # @return [String]
      def key(*args)
        args.compact.join("/")
      end

      # Report url
      #
      # @param [String] path_prefix
      # @return [String]
      def url(path_prefix)
        ["http://#{bucket_name}.s3.amazonaws.com", path_prefix, "index.html"].compact.join("/")
      end
    end
  end
end
