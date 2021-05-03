require "octokit"

module Publisher
  module Providers
    # Github implementation
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

      # Github api client
      #
      # @return [Octokit::Client]
      def client
        @client ||= begin
          raise("Missing GITHUB_AUTH_TOKEN environment variable!") unless ENV["GITHUB_AUTH_TOKEN"]

          Octokit::Client.new(access_token: ENV["GITHUB_AUTH_TOKEN"], api_endpoint: ENV["GITHUB_API_URL"])
        end
      end

      # Pull request run
      #
      # @return [Boolean]
      def pr?
        ENV["GITHUB_EVENT_NAME"] == "pull_request"
      end

      # Pull request description
      #
      # @return [String]
      def pr_description
        @pr_description ||= client.pull_request(repository, pr_id)[:body]
      end

      # Update pull request description
      #
      # @param [String] _desc
      # @return [void]
      def update_pr_description(desc)
        client.update_pull_request(repository, pr_id, body: desc)
      end

      # Pull request id
      #
      # @return [Integer]
      def pr_id
        @pr_id ||= JSON.parse(File.read(ENV["GITHUB_EVENT_PATH"]))["number"]
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
        @build_url ||= "#{server_url}/#{repository}/actions/runs/#{run_id}"
      end

      # Job name
      #
      # @return [String]
      def build_name
        @build_name ||= ENV["GITHUB_JOB"]
      end

      # Github repository
      #
      # @return [String]
      def repository
        @repository ||= ENV["GITHUB_REPOSITORY"]
      end
    end
  end
end
