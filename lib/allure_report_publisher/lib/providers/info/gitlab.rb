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

        # Get gitlab client
        #
        # @return [Gitlab::Client]
        def client
          @client ||= begin
            raise("Missing GITLAB_AUTH_TOKEN environment variable!") unless env("GITLAB_AUTH_TOKEN")

            ::Gitlab::Client.new(
              endpoint: "#{server_url}/api/v4",
              private_token: env("GITLAB_AUTH_TOKEN")
            )
          end
        end

        # Pull request run
        #
        # @return [Boolean]
        def pr?
          !!((allure_project && allure_mr_iid) || mr_iid)
        end

        # Get ci run ID without creating instance of ci provider
        #
        # @return [String]
        def run_id
          @run_id ||= env(ALLURE_RUN_ID) || ENV["CI_PIPELINE_ID"]
        end

        # CI job ID
        #
        # @return [String]
        def job_id
          @job_id ||= env(ALLURE_JOB_ID) || ENV["CI_JOB_ID"]
        end

        # Gitlab pages hostname
        #
        # @return [String]
        def pages_hostname
          @pages_hostname ||= ENV["CI_PAGES_HOSTNAME"]
        end

        # CI project name
        #
        # @return [String]
        def project_name
          @project_name ||= ENV["CI_PROJECT_NAME"]
        end

        # Project directory
        #
        # @return [String] project directory
        def project_dir
          @project_dir ||= ENV["CI_PROJECT_DIR"]
        end

        def branch
          @branch ||= ENV["CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"] || ENV["CI_COMMIT_REF_NAME"]
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

        # Merge request iid
        #
        # @return [Integer]
        def mr_iid
          @mr_iid ||= allure_mr_iid || env("CI_MERGE_REQUEST_IID")
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
