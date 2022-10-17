require "tempfile"

module Publisher
  module Helpers
    # Helper class for gsutil cli utility
    #
    class Gsutil
      class UnsupportedConfig < StandardError; end
      class Uninitialised < StandardError; end

      include Helpers

      def self.init
        new.init!
      end

      private_class_method :new

      # Initialize gsutil
      #
      # @return [Gsutil]
      def init!
        log_debug("Setting up gsutil")
        @valid = execute_shell("which gsutil") && true

        log_debug("Checking google credentials")
        check_credentials
        log_debug("Credentials valid, gsutil initialized")
        self
      rescue StandardError => e
        case e
        when UnsupportedConfig
          log_debug("credentials not compatible with gsutil! Falling back to google sdk client for batch uploads")
        when ShellCommandFailure
          log_debug("gsutil command not found, falling back to gcs client")
        else
          log_debug("gsutil init failed: error: #{e}\nbacktrace: #{e.backtrace&.join("\n")}")
        end

        @valid = false
        self
      end

      # Check if gsutil is valid
      #
      # @return [Boolean]
      def valid?
        @valid
      end

      # Perform batch copy operation
      #
      # @param [String] source_dir
      # @param [String] destination_dir
      # @param [String] bucket
      # @param [String] cache_control
      # @return [void]
      def batch_copy(source_dir:, destination_dir:, bucket:, cache_control: 3600)
        raise(Uninitialised, "gsutil has not been properly set up!") unless valid?

        log_debug("Uploading '#{source_dir}' using gsutil to bucket '#{bucket}' with destination '#{destination_dir}'")
        with_credentials do |key_file|
          execute_shell([
            base_cmd(key_file),
            "-h 'Cache-Control:private, max-age=#{cache_control}'",
            "rsync -r #{source_dir} gs://#{bucket}/#{destination_dir}"
          ].join(" "))
        end
        log_debug("Finished upload successfully")
      end

      private

      # Execute block with gcs credentials
      #
      # @return [void]
      def with_credentials
        if json_key[:file]
          yield(json_key[:key])
        else
          Tempfile.create("auth") do |f|
            f.write(json_key[:key])
            f.close

            yield(f.path)
          end
        end
      end

      # Google auth default credentials
      #
      # @return [String, Hash]
      def gcs_credentials
        @gcs_credentials ||= Google::Cloud::Storage.default_credentials
      end

      # Google auth json key
      #
      # @return [Hash]
      def json_key
        @json_key ||= if gcs_credentials.is_a?(Hash)
                        { file: false, key: gcs_credentials.to_json }
                      elsif gcs_credentials.is_a?(String) && File.exist?(gcs_credentials)
                        { file: true, key: gcs_credentials.tap { |f| JSON.parse(File.read(f)) } }
                      else
                        raise(UnsupportedConfig, "only google key json credentials are supported for gsutil")
                      end
      end
      alias check_credentials json_key

      # Base command
      #
      # @param [String] key_file
      # @return [String]
      def base_cmd(key_file)
        "gsutil -o 'Credentials:gs_service_key_file=#{key_file}' -m"
      end
    end
  end
end
