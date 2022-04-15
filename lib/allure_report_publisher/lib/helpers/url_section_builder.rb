module Publisher
  module Helpers
    # Urls section builder
    #
    class UrlSectionBuilder
      DESCRIPTION_PATTERN = /<!-- allure -->[\s\S]+<!-- allurestop -->/.freeze
      JOBS_PATTERN = /<!-- jobs -->\n([\s\S]+)\n<!-- jobs -->/.freeze

      # Url section builder
      #
      # @param [String] report_url
      # @param [String] report_path
      # @param [String] build_name
      # @param [String] sha_url
      # @param [String] summary_type
      def initialize(report_url:, report_path:, build_name:, sha_url:, summary_type:)
        @report_url = report_url
        @report_path = report_path
        @build_name = build_name
        @sha_url = sha_url
        @summary_type = summary_type
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
        return strip_separator(body) if pr_description.nil? || pr_description.strip == ""
        return "#{pr_description}\n\n#{body}" unless pr_description.match?(DESCRIPTION_PATTERN)

        job_entries = jobs_section(pr_description)
        empty_description = pr_description == pr_description.match(DESCRIPTION_PATTERN)[0]
        pr_description.gsub(
          DESCRIPTION_PATTERN,
          empty_description ? strip_separator(body(job_entries)) : body(job_entries)
        )
      end

      # Allure report url comment without description separator
      #
      # @return [String]
      def comment_body(pr_comment = nil)
        return strip_separator(body) unless pr_comment

        job_entries = jobs_section(pr_comment)
        strip_separator(body(job_entries))
      end

      attr_reader :report_url,
                  :report_path,
                  :build_name,
                  :sha_url,
                  :summary_type

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
        @heading ||= "# Allure report\n`allure-report-publisher` generated test report!"
      end

      # Test run summary
      #
      # @return [Helpers::Summary]
      def summary
        @summary ||= Helpers::Summary.new(report_path, summary_type)
      end

      # Single job report URL entry
      #
      # @return [String]
      def job_entry
        @job_entry ||= begin
          entry = ["<!-- #{build_name} -->"]
          entry << "**#{build_name}**: #{summary.status} [test report](#{report_url}) for #{sha_url}"
          entry << "```markdown\n#{summary.table}\n```" if summary_type
          entry << "<!-- #{build_name} -->"

          entry.join("\n")
        end
      end

      # Job entry pattern
      #
      # @return [RegExp]
      def job_entry_pattern
        @job_entry_pattern ||= /<!-- #{build_name} -->\n([\s\S]+)\n<!-- #{build_name} -->/
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

      # Strip separator from allure results section
      #
      # @param [String] body
      # @return [String]
      def strip_separator(body)
        body.gsub("---\n", "")
      end
    end
  end
end
