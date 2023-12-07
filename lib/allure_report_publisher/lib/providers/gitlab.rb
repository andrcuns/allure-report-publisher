require "gitlab"

module Publisher
  module Providers
    # Gitlab implementation
    #
    class Gitlab < Provider
      include Helpers
      extend Forwardable

      private

      def_delegators :"Publisher::Providers::Info::Gitlab.instance", :allure_project, :allure_mr_iid, :server_url

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

      # rubocop:disable Metrics/PerceivedComplexity
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

        if unresolved_discussion_on_failure && report_has_failures? && !alert_comment
          client.create_merge_request_discussion_note(project, mr_iid, discussion.id, body: alert_comment_text)
        elsif alert_comment && !report_has_failures?
          client.delete_merge_request_discussion_note(project, mr_iid, discussion.id, alert_comment.id)
        end
      end

      # Check if allure report has failures
      #
      # @return [Boolean]
      def report_has_failures?
        main_comment&.body&.include?("❌")
      end

      # rubocop:enable Metrics/PerceivedComplexity

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
