require "aws-sdk-s3"
require "mini_mime"

module Publisher
  module Uploaders
    # Report upload to AWS S3 bucket
    #
    class S3 < Uploader
      # Report url
      #
      # @return [String]
      def report_url
        @report_url ||= url(full_prefix)
      end

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
        log_debug("Downloading previous run history")
        HISTORY.each do |file_name|
          file_path = path(common_info_path, "history", file_name)
          client.get_object(
            response_target: file_path,
            key: key(prefix, "history", file_name),
            bucket: bucket_name
          )
          log_debug("Downloaded '#{file_name}' as '#{file_path}'")
        end
      rescue Aws::S3::Errors::NoSuchKey
        raise(HistoryNotFoundError, "Allure history from previous runs not found!")
      end

      # Upload allure history
      #
      # @return [void]
      def upload_history
        log_debug("Uploading report history")
        upload_to_s3(report_files.select { |file| file.fnmatch?("*/history/*") }, prefix)
      end

      # Upload allure report
      #
      # @return [void]
      def upload_report
        log_debug("Uploading report files")
        upload_to_s3(report_files, full_prefix)
      end

      # Upload copy of latest run
      #
      # @return [void]
      def upload_latest_copy
        log_debug("Copying report as latest")

        # it's not possible to overwrite whole directory so we clean out unique data files from last run
        log_debug("Cleaning data files")
        client.list_objects_v2(bucket: bucket_name, prefix: key(prefix, "data")).each do |resp|
          data_files = resp.contents.map { |obj| { key: obj.key } }
          next if data_files.empty?

          client.delete_objects({ bucket: bucket_name, delete: { objects: data_files } })
        end

        log_debug("Copying report files")
        args = report_files.map do |file|
          {
            bucket: bucket_name,
            copy_source: "/#{bucket_name}/#{key(full_prefix, file.relative_path_from(report_path))}",
            key: key(prefix, file.relative_path_from(report_path)),
            metadata_directive: "REPLACE",
            content_type: content_type(file),
            cache_control: "max-age=60"
          }
        end
        Parallel.each(args, in_threads: PARALLEL_THREADS) { |obj| client.copy_object(obj) }
        log_debug("Finished latest report copy successfully")
      end

      # Upload files to s3
      #
      # @param [Array<Pathname>] files
      # @param [String] key_prefix
      # @return [Array<Hash>]
      def upload_to_s3(files, key_prefix)
        args = files.map do |file|
          {
            body: File.new(file),
            bucket: bucket_name,
            key: key(key_prefix, file.relative_path_from(report_path)),
            content_type: MiniMime.lookup_by_filename(file).content_type,
            cache_control: "max-age=3600"
          }
        end

        log_debug("Uploading '#{args.size}' files in '#{PARALLEL_THREADS}' threads")
        Parallel.each(args, in_threads: PARALLEL_THREADS) { |obj| client.put_object(obj) }
        log_debug("Finished upload successfully")
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
        [base_url || "http://#{bucket_name}.s3.amazonaws.com", path_prefix, "index.html"].compact.join("/")
      end

      # Get file content type
      #
      # @param [Pathname] file
      # @return [String]
      def content_type(file)
        c_type = MiniMime.lookup_by_filename(file)&.content_type
        return c_type if c_type

        log_debug("Content type for '#{file}' not found, using default 'application/octet-stream'")
        "application/octet-stream"
      end
    end
  end
end
