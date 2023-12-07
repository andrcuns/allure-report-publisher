module Publisher
  module Providers
    module Info
      # Github executor info
      #
      class Github < Base
        include Singleton
        include Helpers

        # Executor info
        #
        # @return [Hash]
        def executor(report_url)
          {
            name: "Github",
            type: "github",
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
          env("GITHUB_EVENT_NAME") == "pull_request"
        end

        # Run id
        #
        # @return [String]
        def run_id
          @run_id ||= env("GITHUB_RUN_ID")
        end

        # Server url
        #
        # @return [String]
        def server_url
          @server_url ||= env("GITHUB_SERVER_URL")
        end

        # Job name
        #
        # @return [String]
        def build_name
          @build_name ||= env(ALLURE_JOB_NAME) || env("GITHUB_JOB")
        end

        # Github repository
        #
        # @return [String]
        def repository
          @repository ||= env("GITHUB_REPOSITORY")
        end

        # Build url
        #
        # @return [String]
        def build_url
          @build_url ||= "#{server_url}/#{repository}/actions/runs/#{run_id}"
        end
      end
    end
  end
end
