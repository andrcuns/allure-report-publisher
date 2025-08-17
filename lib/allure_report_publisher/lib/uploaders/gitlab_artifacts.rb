module Publisher
  module Uploaders
    # Uploads artifacts to GitLab
    #
    class GitlabArtifacts < Uploader
      extend Forwardable

      def initialize(**args)
        super

        # gitlab artifacts do not support having url to latest report
        @copy_latest = false
      end

      # Report url
      #
      # @return [String]
      def report_url
        @report_url ||= "https://#{pages_hostname}/-/#{project_name}/-/jobs/#{job_id}/artifacts/#{report_path}/index.html"
      end

      # No-op method as gitlab does not expose api to upload artifacts
      #
      # @return [void]
      def upload
        raise("Gitlab artifacts does not support upload operation! Report upload must be configured in the CI job.")
      end

      private

      def_delegators :ci_info,
                     :pages_hostname,
                     :project_name,
                     :project_id,
                     :job_name,
                     :job_id,
                     :branch,
                     :build_dir,
                     :build_name,
                     :server_url,
                     :client

      # Download allure history
      #
      # @return [void]
      def download_history
        log_debug("Downloading allure history from previous executions")

        unless previous_job_id
          log_debug("Previous execution not found, skipping history download")
          return
        end

        log_debug("Fetching history from artifacts of job: #{previous_job_id}")
        HISTORY.each do |file_name|
          download_artifact_file(
            previous_job_id,
            "#{report_path}/history/#{file_name}",
            path(common_info_path, "history", file_name)
          )
        end
      end

      # Last job from previous pipeline
      #
      # @return [Integer, nil] job id or nil if not found
      def previous_job_id
        return @previous_job_id if defined?(@previous_job_id)

        log_debug("Fetching previous pipelines for ref: #{branch}")
        pipelines = client.pipelines(
          project_id,
          ref: branch,
          per_page: 50
        ).map(&:id)
        return @previous_pipeline_job_id = nil if pipelines.size < 2

        previous_pipeline_index = pipelines.index(run_id) + 1
        return @previous_job_id = nil if previous_pipeline_index >= pipelines.size

        log_debug("Fetching last job id from pipeline: #{pipelines[previous_pipeline_index]}")
        @previous_job_id = client.pipeline_jobs(
          project_id,
          pipelines[previous_pipeline_index],
          scope: %w[success failed]
        ).find { |job| job.name == build_name }&.id
      end

      # Current ref pipelines
      #
      # @return [Array<Hash>]
      def pipelines
        @pipelines ||= client.pipelines(project_id, ref: branch, per_page: 10)
      end

      def latest_job
        @latest_job ||= pipelines.max_by(&:id)
      end

      # CI info
      #
      # @return [Providers::Info::Gitlab]
      def ci_info
        Providers::Info::Gitlab.instance
      end

      # Download specific artifact file
      #
      # @param job_id [Integer] job id
      # @param artifact_path [String] path within artifacts
      # @param local_path [String] local file path to save
      # @return [void]
      def download_artifact_file(job_id, artifact_path, local_path)
        log_debug("Downloading artifact file: #{artifact_path} to #{local_path}")
        # this will only work with history json files, see: https://github.com/NARKOZ/gitlab/issues/621
        response = client.download_job_artifact_file(project_id, job_id, artifact_path)

        File.write(local_path, response.to_json)
      end
    end
  end
end
