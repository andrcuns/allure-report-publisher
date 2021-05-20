require "gitlab"

module Publisher
  module Providers
    # Gitlab implementation
    #
    class Gitlab < Provider
      # Get ci run ID without creating instance of ci provider
      #
      # @return [String]
      def self.run_id
        @run_id ||= ENV["CI_PIPELINE_ID"]
      end

      # Pull request run
      #
      # @return [Boolean]
      def pr?
        ENV["CI_PIPELINE_SOURCE"] == "merge_request_event"
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

      private

      # Current pull request description
      #
      # @return [String]
      def pr_description
        @pr_description ||= client.merge_request(project, mr_iid).description
      end

      # Update pull request description
      #
      # @return [void]
      def update_pr_description
        client.update_merge_request(project, mr_iid, description: updated_pr_description)
      end

      # Add comment with report url
      #
      # @return [void]
      def add_comment
        return client.create_merge_request_comment(project, mr_iid, comment_body) unless comment

        client.edit_merge_request_note(project, mr_iid, comment.id, comment_body)
      end

      # Existing comment with allure urls
      #
      # @return [Gitlab::ObjectifiedHash]
      def comment
        client.merge_request_comments(project, mr_iid).auto_paginate.detect do |comment|
          comment.body.match?(DESCRIPTION_PATTERN)
        end
      end

      # Get gitlab client
      #
      # @return [Gitlab::Client]
      def client
        @client ||= begin
          raise("Missing GITLAB_AUTH_TOKEN environment variable!") unless ENV["GITLAB_AUTH_TOKEN"]

          ::Gitlab::Client.new(
            endpoint: "#{server_url}/api/v4",
            private_token: ENV["GITLAB_AUTH_TOKEN"]
          )
        end
      end

      # Merge request iid
      #
      # @return [Integer]
      def mr_iid
        @mr_iid ||= ENV["CI_MERGE_REQUEST_IID"]
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
        @build_name ||= ENV[ALLURE_JOB_NAME] || ENV["CI_JOB_NAME"]
      end

      # Gitlab repository
      #
      # @return [String]
      def project
        @project ||= ENV["CI_PROJECT_PATH"]
      end

      # Commit sha url
      #
      # @return [String]
      def sha_url
        sha = ENV["CI_COMMIT_SHA"]
        short_sha = ENV["CI_COMMIT_SHORT_SHA"]

        "[#{short_sha}](#{server_url}/#{project}/-/merge_requests/#{mr_iid}/diffs?commit_id=#{sha})"
      end
    end
  end
end
