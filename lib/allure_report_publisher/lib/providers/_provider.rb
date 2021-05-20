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
      DESCRIPTION_PATTERN = /<!-- allure -->[\s\S]+<!-- allurestop -->/.freeze

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
        @reported ||= pr_description.match?(DESCRIPTION_PATTERN)
      end

      # Full PR description
      #
      # @return [String]
      def updated_pr_description
        reported? ? existing_pr_description : initial_pr_descripion
      end

      # Updated PR description
      #
      # @return [String]
      def existing_pr_description
        pr_description.gsub(DESCRIPTION_PATTERN, description_section).strip
      end

      # Initial PR description
      #
      # @return [String]
      def initial_pr_descripion
        "#{pr_description}\n\n#{description_section}".strip
      end

      # Commend body
      #
      # @return [String]
      def comment
        @comment ||= "#{heading}\n\n#{job_entry}"
      end

      # Heading for report urls
      #
      # @return [String]
      def heading
        @heading ||= <<~HEADING.strip
          # Allure report
          `allure-report-publisher` generated allure report for #{sha_url}!
        HEADING
      end

      # Allure report url pr description
      #
      # @return [String]
      def description_section
        @description_section ||= <<~DESC
          <!-- allure -->
          ---
          #{heading}

          #{job_entry}
          <!-- allurestop -->
        DESC
      end

      # Single job report URL entry
      #
      # @return [String]
      def job_entry
        @job_entry ||= "**#{build_name}**: 📝 [allure report](#{report_url})"
      end
    end
  end
end
