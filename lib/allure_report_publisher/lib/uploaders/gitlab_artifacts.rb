module Publisher
  module Uploaders
    # Uploads artifacts to GitLab
    #
    class GitlabArtifacts < Uploader
      extend Forwardable

      def initialize
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
      def upload; end

      private

      def_delegators :ci_info,
                     :pages_hostname,
                     :project_name,
                     :project_id,
                     :job_id,
                     :job_name,
                     :branch,
                     :build_name,
                     :server_url,
                     :client

      # Download allure history
      #
      # @return [void]
      def download_history
        log_debug("Downloading allure history")

        job_id = previous_job_id || previous_pipeline_job_id
        unless job_id
          log_debug("No previous job with artifacts found")
          return
        end

        log_debug("Fetching history from artifacts of job: #{job_id}")
        HISTORY.each do |file_name|
          download_artifact_file(
            job_id,
            "#{report_path}/history/#{file_name}",
            path(common_info_path, "history", file_name)
          )
        end
      end

      # Previous job id within the same pipeline
      #
      # @return [Integer, nil] job id or nil if not found
      def previous_job_id
        return @previous_job_id if defined?(@previous_job_id)

        jobs = client.pipeline_jobs(
          project_id,
          pipeline_id,
          include_retried: true,
          scope: %w[success failed]
        ).map(&:id)
        return @previous_job_id = nil if jobs.size < 2

        @previous_job_id = jobs[jobs.index(job_id.to_i) - 1]
      end

      # Last job from previous pipeline
      #
      # @return [Integer, nil] job id or nil if not found
      def previous_pipeline_job_id
        return @previous_pipeline_job_id if defined?(@previous_pipeline_job_id)

        pipelines = client.pipelines(
          project_id,
          ref: branch,
          per_page: 50
        ).map(&:id)
        return @previous_pipeline_job_id = nil if pipelines.size < 2

        previous_index = pipelines.index(pipeline_id.to_i) - 1
        return @previous_pipeline_job_id = nil if previous_index.negative?

        @previous_pipeline_job_id = client.pipeline_jobs(
          project_id,
          pipelines[previous_index],
          scope: %w[success failed]
        ).find { |job| job.name == build_name }&.id
      end

      # Report path
      #
      # @return [String]
      def report_path
        @report_path ||= File.join(ci_info.project_dir, "allure-report")
      end

      # Allure report generator
      #
      # @return [Publisher::ReportGenerator]
      def report_generator
        @report_generator ||= ReportGenerator.new(result_paths, report_name, report_path)
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

        FileUtils.mkdir_p(File.dirname(local_path))
        File.write(local_path, response.to_json)
      end
    end
  end
end
