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
      # @param [Hash] args
      # @option args [String] :report_url
      # @option args [String] :report_path
      # @option args [Boolean] :update_pr
      # @option args [String] :summary_type
      # @option args [Boolean] :collapse_summay
      # @option args [Boolean] :unresolved_discussion_on_failure
      # @option args [Symbol] :summary_table_type
      def initialize(**args)
        @report_url = args[:report_url]
        @report_path = args[:report_path]
        @update_pr = args[:update_pr]
        @summary_type = args[:summary_type]
        @summary_table_type = args[:summary_table_type]
        @collapse_summary = args[:collapse_summary]
        @unresolved_discussion_on_failure = args[:unresolved_discussion_on_failure]
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
      def add_result_summary
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

      attr_reader :report_url,
                  :report_path,
                  :update_pr,
                  :summary_type,
                  :collapse_summary,
                  :summary_table_type,
                  :unresolved_discussion_on_failure

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
      def url_section_builder
        @url_section_builder ||= Helpers::UrlSectionBuilder.new(
          report_url: report_url,
          report_path: report_path,
          build_name: build_name,
          sha_url: sha_url,
          summary_type: summary_type,
          summary_table_type: summary_table_type,
          collapse_summary: collapse_summary
        )
      end
    end
  end
end
