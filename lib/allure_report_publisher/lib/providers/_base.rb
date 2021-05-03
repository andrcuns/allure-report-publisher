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
    class Base
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

        reported = pr_description.match?(DESCRIPTION_PATTERN)
        return update_pr_description(pr_description.gsub(DESCRIPTION_PATTERN, description_template).strip) if reported

        update_pr_description("#{pr_description}\n#{description_template}".strip)
      end

      private

      attr_reader :results_path, :report_url

      # :nocov:

      # Get executor info
      #
      # @return [Hash]
      def executor_info
        raise("Not implemented!")
      end

      # Pull request run
      #
      # @return [Boolean]
      def pr?
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
      # :nocov:

      # CI run id
      #
      # @return [String]
      def run_id
        self.class.run_id
      end

      # Allure report url pr description
      #
      # @return [String]
      def description_template
        <<~DESC
          <!-- allure -->
          ---
          📝 [Latest allure report](#{report_url})
          <!-- allurestop -->
        DESC
      end
    end
  end
end
