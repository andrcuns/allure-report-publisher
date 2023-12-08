module Publisher
  # Namespace for providers executing tests
  #
  module Providers
    # CI provider class
    #
    # @return [Publisher::Providers::Base]
    def self.provider
      return Github if ENV["GITHUB_WORKFLOW"]

      Gitlab if ENV["GITLAB_CI"]
    end

    # CI info class
    #
    # @return [Info::Base]
    def self.info
      return Info::Github.instance if ENV["GITHUB_WORKFLOW"]

      Info::Gitlab.instance if ENV["GITLAB_CI"]
    end

    # Base class for CI executor info
    #
    class Provider
      # CI provider base
      #
      # @param [Hash] args
      # @option args [String] :report_url
      # @option args [String] :report_path
      # @option args [Boolean] :update_pr
      # @option args [String] :summary_type
      # @option args [Symbol] :summary_table_type
      # @option args [Boolean] :collapse_summay
      # @option args [Boolean] :flaky_warning_status
      # @option args [Boolean] :unresolved_discussion_on_failure
      # @option args [String] :report_title
      def initialize(**args)
        @report_url = args[:report_url]
        @report_path = args[:report_path]
        @update_pr = args[:update_pr]
        @summary_type = args[:summary_type]
        @summary_table_type = args[:summary_table_type]
        @collapse_summary = args[:collapse_summary]
        @flaky_warning_status = args[:flaky_warning_status]
        @unresolved_discussion_on_failure = args[:unresolved_discussion_on_failure]
        @report_title = args[:report_title]
      end

      # Add report url to pull request description
      #
      # @return [void]
      def add_result_summary
        return add_comment if comment?

        update_pr_description
      end

      private

      attr_reader :report_url,
                  :report_path,
                  :update_pr,
                  :summary_type,
                  :collapse_summary,
                  :summary_table_type,
                  :flaky_warning_status,
                  :unresolved_discussion_on_failure,
                  :report_title

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
      # :nocov:

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
          collapse_summary: collapse_summary,
          flaky_warning_status: flaky_warning_status,
          report_title: report_title
        )
      end
    end
  end
end
