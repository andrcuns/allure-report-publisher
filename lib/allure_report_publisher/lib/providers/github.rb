module Publisher
  module Providers
    # Github actions executor info
    #
    class Github < Base
      # Run id
      #
      # @return [String]
      def self.run_id
        @run_id ||= ENV["GITHUB_RUN_ID"]
      end

      private

      # Executor info
      #
      # @return [Hash]
      def executor_info
        {
          name: "Github",
          type: "github",
          reportName: "AllureReport",
          url: server_url,
          reportUrl: report_url,
          buildUrl: build_url,
          buildOrder: run_id,
          buildName: build_name
        }
      end

      # Server url
      #
      # @return [String]
      def server_url
        @server_url ||= ENV["GITHUB_SERVER_URL"]
      end

      # Build url
      #
      # @return [String]
      def build_url
        @build_url ||= "#{server_url}/#{ENV['GITHUB_REPOSITORY']}/actions/runs/#{run_id}"
      end

      def build_name
        @build_name ||= ENV["GITHUB_JOB"]
      end
    end
  end
end
