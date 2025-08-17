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
        # @return [Integer]
        def run_id
          @run_id ||= env_int(ALLURE_RUN_ID) || env_int("CI_PIPELINE_ID")
        end

        # CI job ID
        #
        # @return [Integer]
        def job_id
          @job_id ||= env_int("CI_JOB_ID")
        end

        # Gitlab pages hostname
        #
        # @return [String]
        def pages_hostname
          @pages_hostname ||= env("CI_PAGES_HOSTNAME")
        end

        # CI project name
        #
        # @return [String]
        def project_name
          @project_name ||= env("CI_PROJECT_NAME")
        end

        # CI project ID
        #
        # @return [Integer]
        def project_id
          @project_id ||= env_int("CI_PROJECT_ID")
        end

        # Project directory
        #
        # @return [String] build directory
        def build_dir
          @build_dir ||= env("CI_PROJECT_DIR")
        end

        def branch
          @branch ||= env("CI_MERGE_REQUEST_SOURCE_BRANCH_NAME") || env("CI_COMMIT_REF_NAME")
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
          @mr_iid ||= allure_mr_iid || env_int("CI_MERGE_REQUEST_IID")
        end

        # Custom mr iid name
        #
        # @return [Integer]
        def allure_mr_iid
          @allure_mr_iid ||= env_int("ALLURE_MERGE_REQUEST_IID")
        end

        # Job name used in report
        #
        # @return [String]
        def build_name
          @build_name ||= env(ALLURE_JOB_NAME) || job_name
        end

        # CI job name
        #
        # @return [String]
        def job_name
          @job_name ||= env("CI_JOB_NAME")
        end
      end
    end
  end
end
