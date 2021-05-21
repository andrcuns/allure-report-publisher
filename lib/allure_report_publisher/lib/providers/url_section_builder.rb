module Publisher
  module Providers
    # Urls section builder
    #
    class UrlSectionBuilder
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
      def body(job_entries = job_entry)
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
        @job_entry ||= "**#{build_name}**: 📝 [allure report](#{report_url})<br />"
      end

      # Job entry pattern
      #
      # @return [RegExp]
      def job_entry_pattern
        @job_entry_pattern ||= %r{^\*\*#{build_name}\*\*:.*\[allure report\]\(.*\)<br />$}
      end
    end
  end
end
