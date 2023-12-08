module Publisher
  module Providers
    module Info
      # Gitlab executor info
      #
      class Gitlab < Base
        include Singleton
        include Helpers

        # Executor info
        #
        # @return [Hash]
        def executor(report_url)
          {
            name: "Gitlab",
            type: "gitlab",
            reportName: "AllureReport",
            reportUrl: report_url,
            url: server_url,
            buildUrl: build_url,
            buildOrder: run_id,
            buildName: build_name
          }
        end

        # Pull request run
        #
        # @return [Boolean]
        def pr?
          !!(allure_project && allure_mr_iid) || ENV["CI_PIPELINE_SOURCE"] == "merge_request_event"
        end

        # Get ci run ID without creating instance of ci provider
        #
        # @return [String]
        def run_id
          @run_id ||= ENV["CI_PIPELINE_ID"]
        end

        # Server url
        #
        # @return [String]
        def server_url
          @server_url ||= env("CI_SERVER_URL")
        end

        # Build url
        #
        # @return [String]
        def build_url
          @build_url ||= env("CI_PIPELINE_URL")
        end

        # Custom repository name
        #
        # @return [String]
        def allure_project
          @allure_project ||= env("ALLURE_PROJECT_PATH")
        end

        # Custom mr iid name
        #
        # @return [String]
        def allure_mr_iid
          @allure_mr_iid ||= env("ALLURE_MERGE_REQUEST_IID")
        end

        # Job name
        #
        # @return [String]
        def build_name
          @build_name ||= env(ALLURE_JOB_NAME) || env("CI_JOB_NAME")
        end
      end
    end
  end
end
