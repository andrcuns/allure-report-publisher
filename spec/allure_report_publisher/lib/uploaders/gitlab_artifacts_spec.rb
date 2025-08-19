require_relative "common_uploader"
require_relative "../providers/gitlab_env"

RSpec.describe Publisher::Uploaders::GitlabArtifacts, epic: "uploaders" do
  include_context "with uploader"
  include_context "with gitlab env"

  let(:client) do
    instance_double(
      Gitlab::Client,
      pipelines: pipelines_response,
      pipeline_jobs: jobs_response,
      download_job_artifact_file: artifact_response
    )
  end

  let(:pipelines_response) do
    [
      double("pipeline", id: current_pipeline_id),
      double("pipeline", id: previous_pipeline_id),
      double("pipeline", id: older_pipeline_id)
    ]
  end

  let(:jobs_response) do
    [
      double("job", name: "test", id: previous_job_id),
      double("job", name: "other", id: 999)
    ]
  end

  let(:artifact_response) { double(Gitlab::FileResponse, string: '{"key":"value"}') }
  let(:current_pipeline_id) { 123 }
  let(:previous_pipeline_id) { 122 }
  let(:older_pipeline_id) { 121 }
  let(:previous_job_id) { 456 }
  let(:job_name) { "test" }
  let(:job_id) { "789" }
  let(:project_id) { "123" }
  let(:branch) { "main" }
  let(:run_id) { current_pipeline_id }

  let(:expected_url) do
    "https://#{top_level_group}.gitlab.io/-/#{project_name}/-/jobs/#{job_id}/artifacts/#{report_path}/index.html"
  end

  let(:ci_info) do
    instance_double(
      Publisher::Providers::Info::Gitlab,
      project_path: "#{top_level_group}/#{project_name}",
      project_id: project_id,
      job_name: job_name,
      job_id: job_id,
      branch: branch,
      build_dir: "build",
      build_name: job_name,
      server_url: "https://gitlab.example.com",
      client: client,
      run_id: run_id,
      executor: {}
    )
  end

  before do
    allow(Publisher::Providers::Info::Gitlab).to receive(:instance).and_return(ci_info)
    allow(File).to receive(:write)
    allow(File).to receive(:exist?).and_return(false)
    allow(FileUtils).to receive(:mkdir_p).and_return(["/tmp/history"])
  end

  def execute(allure_extra_args: [], **extra_args)
    uploader = described_class.new(**args, **extra_args)
    uploader.generate_report(allure_extra_args)
  end

  context "with initialization" do
    it "sets copy_latest to false" do
      uploader = described_class.new(**args)
      expect(uploader.instance_variable_get(:@copy_latest)).to be false
    end
  end

  context "with default base url" do
    it "returns correct GitLab artifacts report url" do
      uploader = described_class.new(**args)

      expect(uploader.report_url).to eq(expected_url)
    end
  end

  context "with custom base url" do
    let(:base_url) { "http://custom.gitlab.com" }

    it "returns correct GitLab artifacts report url" do
      uploader = described_class.new(**args)

      expect(uploader.report_url).to eq(
        "http://#{top_level_group}.custom.gitlab.com/-/#{project_name}/-/jobs/#{job_id}/artifacts/#{report_path}/index.html"
      )
    end
  end

  context "with upload operation" do
    it "raises error when upload is called" do
      uploader = described_class.new(**args)

      expect { uploader.upload }.to raise_error(
        "Gitlab artifacts does not support upload operation! Report upload must be configured in the CI job."
      )
    end
  end

  context "with report generation" do
    it "generates allure report" do
      execute(allure_extra_args: ["--lang=en"])

      aggregate_failures do
        expect(Publisher::ReportGenerator).to have_received(:new).with(result_paths, report_name, report_path)
        expect(report_generator).to have_received(:generate).with(["--lang=en"])
      end
    end

    it "fetches and saves history info when previous job exists" do
      execute

      aggregate_failures do
        expect(client).to have_received(:pipelines).with(
          project_id,
          ref: branch,
          per_page: 50
        )
        expect(client).to have_received(:pipeline_jobs).with(
          project_id,
          previous_pipeline_id,
          scope: %w[success failed]
        )

        history_files.each do |file_name|
          expect(client).to have_received(:download_job_artifact_file).with(
            project_id,
            previous_job_id,
            "#{report_path}/history/#{file_name}"
          )
        end
      end
    end
  end

  context "with history download" do
    context "when no previous job exists" do
      let(:pipelines_response) { [double("pipeline", id: current_pipeline_id)] }

      it "skips history download" do
        execute

        expect(client).not_to have_received(:download_job_artifact_file)
      end
    end

    context "when previous pipeline has no matching job" do
      let(:jobs_response) do
        [
          double("job", name: "different-job", id: 999)
        ]
      end

      it "skips history download" do
        execute

        expect(client).not_to have_received(:download_job_artifact_file)
      end
    end

    context "when multiple pipelines exist with matching job" do
      it "finds and uses correct previous job ID for history download" do
        execute

        aggregate_failures do
          expect(client).to have_received(:pipelines).with(
            project_id,
            ref: branch,
            per_page: 50
          )
          expect(client).to have_received(:pipeline_jobs).with(
            project_id,
            previous_pipeline_id,
            scope: %w[success failed]
          )

          # Verify the correct previous job ID was found and used
          history_files.each do |file_name|
            expect(client).to have_received(:download_job_artifact_file).with(
              project_id,
              previous_job_id,
              "#{report_path}/history/#{file_name}"
            )
          end
        end
      end
    end

    context "when artifact download succeeds" do
      it "saves artifact files as JSON" do
        execute

        expect(FileUtils).to have_received(:mkdir_p).with(File.join(common_info_path, "history"))

        history_files.each do |file_name|
          file_path = File.join(common_info_path, "history", file_name)
          expect(File).to have_received(:write).with(file_path, artifact_response.string)
        end
      end
    end
  end

  context "with executor info" do
    context "when executor file doesn't exist" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "writes executor info to both common_info_path and result_paths" do
        execute

        expect(File).to have_received(:write).with("#{common_info_path}/executor.json", JSON.pretty_generate({})).twice
      end
    end

    context "when executor file already exists" do
      before do
        allow(File).to receive(:exist?).and_return(true)
      end

      it "skips writing executor info" do
        execute

        expect(File).not_to have_received(:write).with("#{common_info_path}/executor.json", anything)
      end
    end
  end

  context "with report URLs" do
    it "returns only report url (no latest report url)" do
      uploader = described_class.new(**args, copy_latest: true)

      expect(uploader.report_urls).to eq({
        "Report url" => expected_url
      })
    end
  end

  context "with artifact file download integration" do
    # Test the artifact download behavior through the public generate_report method
    # which internally calls download_artifact_file for each history file

    context "when downloading multiple artifact files" do
      it "downloads all history files and saves them as JSON" do
        execute

        aggregate_failures do
          # Verify all history files were requested from the correct job
          history_files.each do |file_name|
            expect(client).to have_received(:download_job_artifact_file).with(
              project_id,
              previous_job_id,
              "#{report_path}/history/#{file_name}"
            )

            file_path = File.join(common_info_path, "history", file_name)
            expect(File).to have_received(:write).with(file_path, artifact_response.string)
          end

          # Verify directory was created
          expect(FileUtils).to have_received(:mkdir_p).with(File.join(common_info_path, "history"))
        end
      end
    end

    context "when artifact download encounters network errors" do
      before do
        # Use HistoryNotFoundError which is the expected error type that gets handled
        allow(client).to receive(:download_job_artifact_file).and_raise(
          StandardError, "History not found"
        )
      end

      it "handles history download errors gracefully and continues" do
        expect { execute }.not_to raise_error

        # Should still try to download history files
        expect(client).to have_received(:download_job_artifact_file)

        # But no files should be written due to the error
        expect(File).not_to have_received(:write).with(anything, artifact_response.string)
      end
    end
  end
end
