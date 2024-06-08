require "gitlab"

module Publisher
  module Providers
    # Gitlab implementation
    #
    class Gitlab < Provider
      include Helpers
      extend Forwardable

      private

      def_delegators :"Publisher::Providers::Info::Gitlab.instance",
                     :allure_project,
                     :mr_iid,
                     :allure_mr_iid,
                     :server_url,
                     :build_name

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

      # Current pull request description
      #
      # @return [String]
      def pr_description
        @pr_description ||= client.merge_request(project, mr_iid).description
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

      # Commit sha url
      #
      # @return [String]
      def sha_url
        sha = allure_sha || env("CI_MERGE_REQUEST_SOURCE_BRANCH_SHA") || env("CI_COMMIT_SHA")
        short_sha = sha[0..7]

        "[#{short_sha}](#{server_url}/#{project}/-/merge_requests/#{mr_iid}/diffs?commit_id=#{sha})"
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

      # Add comment with report url
      #
      # @return [void]
      def add_comment
        create_or_update_comment
      end

      # Create or update comment with report url
      #
      # @return [void]
      def create_or_update_comment
        unless comment
          log_debug("Creating comment with summary for mr !#{mr_iid}")
          return client.create_merge_request_comment(project, mr_iid, url_section_builder.comment_body) unless comment
        end

        log_debug("Creating comment with summary for mr !#{mr_iid}")
        client.edit_merge_request_note(project, mr_iid, comment.id, url_section_builder.comment_body(comment.body))
      end

      # Check if allure report has failures
      #
      # @return [Boolean]
      def report_has_failures?
        main_comment&.body&.include?("❌")
      end

      # Existing comment with allure urls
      #
      # @return [Gitlab::ObjectifiedHash]
      def comment
        client.merge_request_comments(project, mr_iid).auto_paginate.detect do |comment|
          Helpers::UrlSectionBuilder.match?(comment.body)
        end
      end
    end
  end
end
