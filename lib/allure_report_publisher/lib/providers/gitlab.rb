require "gitlab"

module Publisher
  module Providers
    # Gitlab implementation
    #
    class Gitlab < Provider
      include Helpers

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
        (allure_project && allure_mr_iid) || ENV["CI_PIPELINE_SOURCE"] == "merge_request_event"
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
        log_debug("Updating mr description for mr !#{mr_iid}")
        client.update_merge_request(
          project,
          mr_iid,
          description: url_section_builder.updated_pr_description(pr_description)
        )
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # Add comment with report url
      #
      # @return [void]
      def add_comment
        if main_comment
          log_debug("Updating summary in comment with id #{discussion.id} in mr !#{mr_iid}")

          client.edit_merge_request_note(
            project,
            mr_iid,
            main_comment.id,
            url_section_builder.comment_body(main_comment.body)
          )
        else
          log_debug("Creating comment with summary for mr ! #{mr_iid}")
          client.create_merge_request_comment(project, mr_iid, url_section_builder.comment_body)
        end

        @discussion = nil

        if unresolved_discussion_on_failure && main_comment&.body&.include?("❌") && !alert_comment
          client.create_merge_request_discussion_note(project, mr_iid, discussion.id, body: alert_comment_text)
        elsif alert_comment
          client.delete_merge_request_discussion_note(project, mr_iid, discussion.id, alert_comment.id)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Existing discussion that has comment with allure urls
      #
      # @return [Gitlab::ObjectifiedHash]
      def discussion
        @discussion ||= client.merge_request_discussions(project, mr_iid).auto_paginate.detect do |discussion|
          discussion.notes.any? { |note| Helpers::UrlSectionBuilder.match?(note.body) }
        end
      end

      # Comment/note with allure urls
      #
      # @return [Gitlab::ObjectifiedHash]
      def main_comment
        discussion&.notes&.detect { |note| Helpers::UrlSectionBuilder.match?(note.body) }
      end

      # Comment with alert text
      #
      # @return [Gitlab::ObjectifiedHash]
      def alert_comment
        @alert_comment ||= discussion&.notes&.detect do |note|
          note.body.include?(alert_comment_text)
        end
      end

      # Text for alert comment
      #
      # @return [String]
      def alert_comment_text
        @alert_comment_text ||=
          env("ALLURE_FAILURE_ALERT_COMMENT") || "There are some test failures that need attention"
      end

      # Get gitlab client
      #
      # @return [Gitlab::Client]
      def client
        @client ||= begin
          raise("Missing GITLAB_AUTH_TOKEN environment variable!") unless env("GITLAB_AUTH_TOKEN")

          ::Gitlab::Client.new(
            endpoint: "#{server_url}/api/v4",
            private_token: env("GITLAB_AUTH_TOKEN")
          )
        end
      end

      # Custom repository name
      #
      # @return [String]
      def allure_project
        @allure_project ||= env("ALLURE_PROJECT_PATH")
      end

      # Custom mr iid name
      #
      # @return [String]
      def allure_mr_iid
        @allure_mr_iid ||= env("ALLURE_MERGE_REQUEST_IID")
      end

      # Custom sha
      #
      # @return [String]
      def allure_sha
        @allure_sha ||= env("ALLURE_COMMIT_SHA")
      end

      # Gitlab project path
      #
      # @return [String]
      def project
        @project ||= allure_project || env("CI_MERGE_REQUEST_PROJECT_PATH") || env("CI_PROJECT_PATH")
      end

      # Merge request iid
      #
      # @return [Integer]
      def mr_iid
        @mr_iid ||= allure_mr_iid || env("CI_MERGE_REQUEST_IID")
      end

      # Server url
      #
      # @return [String]
      def server_url
        @server_url ||= env("CI_SERVER_URL")
      end

      # Build url
      #
      # @return [String]
      def build_url
        @build_url ||= env("CI_PIPELINE_URL")
      end

      # Job name
      #
      # @return [String]
      def build_name
        @build_name ||= env(ALLURE_JOB_NAME) || env("CI_JOB_NAME")
      end

      # Commit sha url
      #
      # @return [String]
      def sha_url
        sha = allure_sha || env("CI_MERGE_REQUEST_SOURCE_BRANCH_SHA") || env("CI_COMMIT_SHA")
        short_sha = sha[0..7]

        "[#{short_sha}](#{server_url}/#{project}/-/merge_requests/#{mr_iid}/diffs?commit_id=#{sha})"
      end
    end
  end
end
