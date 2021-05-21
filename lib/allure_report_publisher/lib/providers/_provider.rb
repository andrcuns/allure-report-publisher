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
      DESCRIPTION_PATTERN = /<!-- allure -->[\s\S]+<!-- allurestop -->/.freeze
      JOBS_PATTERN = /<!-- jobs -->\n([\s\S]+)\n<!-- jobs -->/.freeze

      def initialize(report_url:, build_name:, sha_url:)
        @report_url = report_url
        @build_name = build_name
        @sha_url = sha_url
      end

      # Matches url section pattern
      #
      # @param [String] urls_block
      # @return [Boolean]
      def self.match?(urls_block)
        urls_block.match?(DESCRIPTION_PATTERN)
      end

      # Get urls for PR update
      #
      # @param [String] pr
      # @return [String]
      def updated_pr_description(pr_description)
        return "#{pr_description}\n\n#{body}" unless pr_description.match?(DESCRIPTION_PATTERN)

        job_entries = jobs_section(pr_description)
        pr_description.gsub(DESCRIPTION_PATTERN, body(job_entries))
      end

      # Allure report url comment
      #
      # @return [String]
      def comment_body(pr_comment = nil)
        return body.gsub("---\n", "") unless pr_comment

        job_entries = jobs_section(pr_comment)
        body(job_entries).gsub("---\n", "")
      end

      attr_reader :report_url, :build_name, :sha_url

      private

      # Allure report url pr description
      #
      # @return [String]
      def body(job_entries = "**#{build_name}**: 📝 [allure report](#{report_url})")
        @body ||= <<~BODY.strip
          <!-- allure -->
          ---
          #{heading}

          <!-- jobs -->
          #{job_entries}
          <!-- jobs -->
          <!-- allurestop -->
        BODY
      end

      # Url section heading
      #
      # @return [String]
      def heading
        @heading ||= "# Allure report\n`allure-report-publisher` generated allure report for #{sha_url}!"
      end

      # Return updated jobs section
      #
      # @param [String] urls
      # @return [String]
      def jobs_section(urls_block)
        jobs = urls_block.match(JOBS_PATTERN)[1]
        return jobs.gsub(job_entry_pattern, job_entry) if jobs.match?(job_entry_pattern)

        "#{jobs}\n#{job_entry}"
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
        @job_entry_pattern ||= /^\*\*#{build_name}\*\*:.*\[allure report\]\(.*\)$/
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
        @report_urls ||= ReportUrls.new(report_url: report_url, build_name: build_name, sha_url: sha_url)
      end
    end
  end
end
