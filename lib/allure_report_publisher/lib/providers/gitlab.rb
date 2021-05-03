module Publisher
  module Providers
    # Gitlab implementation
    #
    class Gitlab < Base
      # Get ci run ID without creating instance of ci provider
      #
      # @return [String]
      def self.run_id
        @run_id ||= ENV["CI_PIPELINE_ID"]
      end

      # Get executor info
      #
      # @return [Hash]
      def executor_info
        {
          name: "Gitlab",
          type: "gitlab",
          reportName: "AllureReport",
          url: server_url,
          reportUrl: report_url,
          buildUrl: build_url,
          buildOrder: run_id,
          buildName: build_name
        }
      end

      # Pull request run
      #
      # @return [Boolean]
      def pr?
        ENV["CI_PIPELINE_SOURCE"] == "merge_request_event"
      end

      # Server url
      #
      # @return [String]
      def server_url
        @server_url ||= ENV["CI_SERVER_URL"]
      end

      # Build url
      #
      # @return [String]
      def build_url
        @build_url ||= ENV["CI_PIPELINE_URL"]
      end

      # Job name
      #
      # @return [String]
      def build_name
        @build_name ||= ENV["CI_JOB_NAME"]
      end

      # Github repository
      #
      # @return [String]
      def repository
        @repository ||= ENV["CI_PROJECT_PATH"]
      end
    end
  end
end
