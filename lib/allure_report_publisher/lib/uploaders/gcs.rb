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
        log_debug("Copying report as latest")

        args = report_files.map do |file|
          {
            source_file: bucket.file(key(full_prefix, file.relative_path_from(report_path))),
            destination: key(prefix, file.relative_path_from(report_path))
          }
        end

        Parallel.each(args, in_threads: PARALLEL_THREADS) do |obj|
          obj[:source_file].copy(obj[:destination], force_copy_metadata: true) do |f|
            f.cache_control = "public, max-age=60"
          end
        end
        log_debug("Finished latest report copy successfully")
      end

      # Upload files to gcs
      #
      # @param [Array<Pathname>] files
      # @param [String] key_prefix
      # @param [Hash] params
      # @return [Array<Hash>]
      def upload_to_gcs(files, key_prefix)
        args = files.map do |file|
          {
            file: file.to_s,
            path: key(key_prefix, file.relative_path_from(report_path))
          }
        end

        log_debug("Uploading '#{args.size}' files in '#{PARALLEL_THREADS}' threads")
        Parallel.each(args, in_threads: PARALLEL_THREADS) do |obj|
          bucket.create_file(*obj.slice(:file, :path).values, cache_control: "public, max-age=3600")
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
