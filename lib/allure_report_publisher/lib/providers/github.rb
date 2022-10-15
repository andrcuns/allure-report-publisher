require "octokit"

module Publisher
  module Providers
    # Github implementation
    #
    class Github < Provider
      include Helpers

      # Set octokit to autopaginate
      #
      Octokit.configure do |config|
        config.auto_paginate = true
      end

      # Run id
      #
      # @return [String]
      def self.run_id
        @run_id ||= ENV["GITHUB_RUN_ID"]
      end

      # Pull request run
      #
      # @return [Boolean]
      def pr?
        ENV["GITHUB_EVENT_NAME"] == "pull_request"
      end

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

      private

      # Github api client
      #
      # @return [Octokit::Client]
      def client
        @client ||= begin
          raise("Missing GITHUB_AUTH_TOKEN environment variable!") unless ENV["GITHUB_AUTH_TOKEN"]

          Octokit::Client.new(access_token: ENV["GITHUB_AUTH_TOKEN"], api_endpoint: ENV["GITHUB_API_URL"])
        end
      end

      # Update pull request description
      #
      # @return [void]
      def update_pr_description
        return File.write(step_summary_file, url_section_builder.comment_body) if actions?

        log_debug("Updating pr description for pr !#{pr_id}")
        client.update_pull_request(repository, pr_id, body: url_section_builder.updated_pr_description(pr_description))
      end

      # Add comment with report url
      #
      # @return [void]
      def add_comment
        unless comment
          log_debug("Creating comment with summary for pr ! #{pr_id}")
          return client.add_comment(repository, pr_id, url_section_builder.comment_body)
        end

        log_debug("Updating summary in comment with id #{comment[:id]} in pr !#{pr_id}")
        client.update_comment(repository, comment[:id], url_section_builder.comment_body(comment[:body]))
      end

      # Existing comment with allure urls
      #
      # @return [Sawyer::Resource]
      def comment
        @comment ||= client.issue_comments(repository, pr_id).detect do |comment|
          Helpers::UrlSectionBuilder.match?(comment[:body])
        end
      end

      # Github event
      #
      # @return [Hash]
      def github_event
        @github_event ||= JSON.parse(File.read(ENV["GITHUB_EVENT_PATH"]), symbolize_names: true)
      end

      # Pull request description
      #
      # @return [String]
      def pr_description
        @pr_description ||= client.pull_request(repository, pr_id)[:body]
      end

      # Pull request id
      #
      # @return [Integer]
      def pr_id
        @pr_id ||= github_event[:number]
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
        @build_name ||= ENV[ALLURE_JOB_NAME] || ENV["GITHUB_JOB"]
      end

      # Github repository
      #
      # @return [String]
      def repository
        @repository ||= ENV["GITHUB_REPOSITORY"]
      end

      # Commit sha url
      #
      # @return [String]
      def sha_url
        sha = github_event.dig(:pull_request, :head, :sha)
        short_sha = sha[0..7]

        "[#{short_sha}](#{server_url}/#{repository}/pull/#{pr_id}/commits/#{sha})"
      end

      # Use actions summary for results
      #
      # @return [Boolean]
      def actions?
        update_pr == "actions"
      end

      # Github actions summary file
      #
      # @return [String]
      def step_summary_file
        @step_summary_file ||= begin
          summary_file = ENV["GITHUB_STEP_SUMMARY"]
          raise("Environment variable GITHUB_STEP_SUMMARY is empty!") unless summary_file
          raise("Step summary file '#{summary_file}' does not exist!") unless File.exist?(summary_file)

          summary_file
        end
      end
    end
  end
end
