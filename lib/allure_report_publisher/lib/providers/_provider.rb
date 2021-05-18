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
      EXECUTOR_JSON = "executor.json".freeze
      DESCRIPTION_PATTERN = /<!-- allure -->[\s\S]+<!-- allurestop -->/.freeze

      def initialize(results_path, report_url)
        @results_path = results_path
        @report_url = report_url
      end

      # :nocov:

      # Get ci run ID without creating instance of ci provider
      #
      # @return [String]
      def self.run_id
        raise("Not implemented!")
      end
      # :nocov:

      # Write executor info file
      #
      # @return [void]
      def write_executor_info
        File.open("#{results_path}/#{EXECUTOR_JSON}", "w") do |file|
          file.write(executor_info.to_json)
        end
      end

      # Add report url to pull request description
      #
      # @return [void]
      def add_report_url
        raise("Not a pull request, skipped!") unless pr?
        return update_pr_description(updated_pr_description) if reported?

        update_pr_description(initial_pr_descripion)
      end

      # :nocov:

      # Pull request run
      #
      # @return [Boolean]
      def pr?
        raise("Not implemented!")
      end

      private

      attr_reader :results_path, :report_url

      # Get executor info
      #
      # @return [Hash]
      def executor_info
        raise("Not implemented!")
      end

      # Current pull request description
      #
      # @return [String]
      def pr_description
        raise("Not implemented!")
      end

      # Update pull request description
      #
      # @param [String] _desc
      # @return [void]
      def update_pr_description(_desc)
        raise("Not implemented!")
      end

      def comment_report_urls
        raise("Not implemented!")
      end
      # :nocov:

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

      # Updated PR description
      #
      # @return [String]
      def updated_pr_description
        pr_description.gsub(DESCRIPTION_PATTERN, report_url_section).strip
      end

      # Initial PR description
      #
      # @return [String]
      def initial_pr_descripion
        "#{pr_description}\n\n#{report_url_section}".strip
      end

      # Allure report url pr description
      #
      # @return [String]
      def report_url_section
        @report_url_section ||= <<~DESC
          <!-- allure -->
          ---
          #{job_entry}
          <!-- allurestop -->
        DESC
      end

      # Single job report URL entry
      #
      # @return [String]
      def job_entry
        @job_entry ||= "`#{build_name}`: 📝 [allure report](#{report_url})"
      end
    end
  end
end
