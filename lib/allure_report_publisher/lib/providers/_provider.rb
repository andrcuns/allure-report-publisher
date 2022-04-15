module Publisher
  # Namespace for providers executing tests
  #
  module Providers
    # Detect CI provider
    #
    # @return [Publisher::Providers::Base]
    def self.provider
      return Github if ENV["GITHUB_WORKFLOW"]
      return Gitlab if ENV["GITLAB_CI"]
    end

    # Base class for CI executor info
    #
    class Provider
      ALLURE_JOB_NAME = "ALLURE_JOB_NAME".freeze

      # CI provider base
      #
      # @param [String] report_url
      # @param [Boolean] update_pr
      def initialize(report_url:, update_pr:)
        @report_url = report_url
        @update_pr = update_pr
      end

      # :nocov:

      # Get ci run ID without creating instance of ci provider
      #
      # @return [String]
      def self.run_id
        raise("Not implemented!")
      end

      # Get executor info
      #
      # @return [Hash]
      def executor_info
        raise("Not implemented!")
      end
      # :nocov:

      # Add report url to pull request description
      #
      # @return [void]
      def add_report_url
        raise("Not a pull request, skipped!") unless pr?
        return add_comment if comment?

        update_pr_description
      end

      # :nocov:

      # Pull request run
      #
      # @return [Boolean]
      def pr?
        raise("Not implemented!")
      end

      private

      attr_reader :report_url, :update_pr

      # Current pull request description
      #
      # @return [String]
      def pr_description
        raise("Not implemented!")
      end

      # Update pull request description
      #
      # @return [void]
      def update_pr_description
        raise("Not implemented!")
      end

      # Add comment with report url
      #
      # @return [void]
      def add_comment
        raise("Not implemented!")
      end

      # Build name
      #
      # @return [String]
      def build_name
        raise("Not implemented!")
      end

      # Commit SHA url
      #
      # @return [String]
      def sha_url
        raise("Not implemented!")
      end
      # :nocov:

      # CI run id
      #
      # @return [String]
      def run_id
        self.class.run_id
      end

      # Add report url as comment
      #
      # @return [Boolean]
      def comment?
        update_pr == "comment"
      end

      # Report urls section creator
      #
      # @return [ReportUrls]
      def report_urls
        @report_urls ||= UrlSectionBuilder.new(report_url: report_url, build_name: build_name, sha_url: sha_url)
      end
    end
  end
end
