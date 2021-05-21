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

    # Urls section builder
    #
    class ReportUrls
      DESCRIPTION_PATTERN = /<!-- allure -->([\s\S]+)<!-- allurestop -->/.freeze

      def initialize(report_url:, build_name:, sha_url:)
        @report_url = report_url
        @build_name = build_name
        @sha_url = sha_url
      end

      # Matches url section pattern
      #
      # @param [String] urls
      # @return [Boolean]
      def self.match?(urls)
        urls.match?(DESCRIPTION_PATTERN)
      end

      # Get urls for PR update
      #
      # @param [String] pr
      # @return [String]
      def updated_pr_description(pr_description)
        return "#{pr_description}\n\n#{body}".strip unless pr_description.match?(DESCRIPTION_PATTERN)

        pr_description.gsub(DESCRIPTION_PATTERN, body).strip
      end

      # Allure report url comment
      #
      # @return [String]
      def comment_body(_pr_comment = nil)
        body.gsub("---\n", "")
      end

      attr_reader :report_url, :build_name, :sha_url

      private

      # Allure report url pr description
      #
      # @return [String]
      def body
        @body ||= "<!-- allure -->\n---\n#{heading}\n\n#{job_entry}\n<!-- allurestop -->\n"
      end

      # Url section heading
      #
      # @return [String]
      def heading
        @heading ||= "# Allure report\n`allure-report-publisher` generated allure report for #{sha_url}!"
      end

      # Single job report URL entry
      #
      # @return [String]
      def job_entry
        @job_entry ||= "**#{build_name}**: 📝 [allure report](#{report_url})"
      end

      # Job entry pattern
      #
      # @return [RegExp]
      def job_entry_pattern
        @job_entry_pattern ||= /^\*\*#{build_name}\*\*: 📝 \[allure report\]S+$/
      end
    end

    # Base class for CI executor info
    #
    class Provider
      ALLURE_JOB_NAME = "ALLURE_JOB_NAME".freeze

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

      # Add report url as comment
      #
      # @return [Boolean]
      def comment?
        update_pr == "comment"
      end

      # CI run id
      #
      # @return [String]
      def run_id
        self.class.run_id
      end

      # Check if PR already has report urls
      #
      # @return [Boolean]
      def reported?
        @reported ||= ReportUrls.match?(pr_description)
      end

      # Report urls section creator
      #
      # @return [ReportUrls]
      def report_urls
        @report_urls ||= ReportUrls.new(report_url: report_url, build_name: build_name, sha_url: sha_url)
      end
    end
  end
end
