require "google/cloud/storage"

module Publisher
  module Uploaders
    # Google cloud storage uploader implementation
    #
    class GCS < Uploader
      private

      # GCS client
      #
      # @return [Google::Cloud::Storage::Project]
      def client
        @client ||= Google::Cloud::Storage.new
      end

      # GCS bucket
      #
      # @return [Google::Cloud::Storage::Bucket]
      def bucket
        @bucket ||= client.bucket(bucket_name, skip_lookup: true)
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

      # Download allure history
      #
      # @return [void]
      def download_history
        log_debug("Downloading previous run history")
        HISTORY.each do |file_name|
          file = bucket.file(key(prefix, "history", file_name))
          raise(HistoryNotFoundError, "Allure history from previous runs not found!") unless file

          file_path = path(common_info_path, "history", file_name)
          file.download(file_path)
          log_debug("Downloaded '#{file_name}' as '#{file_path}'")
        end
      end

      # Upload allure history
      #
      # @return [void]
      def upload_history
        log_debug("Uploading report history")
        upload_to_gcs(report_files.select { |file| file.fnmatch?("*/history/*") }, prefix)
      end

      # Upload allure report
      #
      # @return [void]
      def upload_report
        log_debug("Uploading report files")
        upload_to_gcs(report_files, full_prefix)
      end

      # Upload copy of latest run
      #
      # @return [void]
      def upload_latest_copy
        log_debug("Uploading report copy as latest report")
        upload_to_gcs(report_files, prefix, cache_control: 60)
      end

      # Upload files to gcs
      #
      # @param [Array<Pathname>] files
      # @param [String] key_prefix
      # @param [Hash] params
      # @return [Array<Hash>]
      def upload_to_gcs(files, key_prefix, cache_control: 3600)
        threads = 8
        args = files.map do |file|
          {
            file: file.to_s,
            path: key(key_prefix, file.relative_path_from(report_path)),
            cache_control: "public, max-age=#{cache_control}"
          }
        end

        log_debug("Uploading '#{args.size}' files in '#{threads}' threads")
        Parallel.each(args, in_threads: threads) do |obj|
          bucket.create_file(*obj.slice(:file, :path).values, **obj.slice(:cache_control))
        end
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
        ["https://storage.googleapis.com", bucket_name, path_prefix, "index.html"].compact.join("/")
      end
    end
  end
end
