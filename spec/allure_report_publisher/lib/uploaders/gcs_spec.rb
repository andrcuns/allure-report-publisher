require_relative "common_uploader"
require_relative "../providers/gitlab_env"

# rubocop:disable Layout/LineLength
RSpec.describe Publisher::Uploaders::GCS, epic: "uploaders" do
  include_context "with uploader"

  let(:client) { instance_double(Google::Cloud::Storage::Project, bucket: bucket) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket, create_file: nil, file: file) }
  let(:file) { instance_double(Google::Cloud::Storage::File, download: nil, copy: nil) }
  let(:cache_control) { { cache_control: "public, max-age=3600" } }

  let(:history) do
    {
      file: instance_double(Google::Cloud::Storage::File, download: nil, copy: nil),
      path: "spec/fixture/fake_report/history/history.json",
      gcs_path_run: "#{prefix}/#{run_id}/history/history.json",
      gcs_path_latest: "#{prefix}/history/history.json"
    }
  end

  let(:report) do
    {
      file: instance_double(Google::Cloud::Storage::File, download: nil, copy: nil),
      existing_file: instance_double(Google::Cloud::Storage::File, delete: nil),
      path: "spec/fixture/fake_report/index.html",
      gcs_path_run: "#{prefix}/#{run_id}/index.html",
      gcs_path_latest: "#{prefix}/index.html"
    }
  end

  def execute(allure_extra_args: [], **extra_args)
    uploader = described_class.new(**args, **extra_args)
    uploader.generate_report(allure_extra_args)
    uploader.upload
  end

  before do
    allow(Google::Cloud::Storage).to receive(:new) { client }
  end

  context "with non ci run" do
    around do |example|
      ClimateControl.modify(GITHUB_WORKFLOW: nil, GITLAB_CI: nil) { example.run }
    end

    it "generates allure report" do
      execute(allure_extra_args: ["--lang=en"])

      aggregate_failures do
        expect(Publisher::ReportGenerator).to have_received(:new).with(result_paths, report_name, report_path)
        expect(report_generator).to have_received(:generate).with(["--lang=en"])
      end
    end

    it "uploads allure report" do
      execute

      aggregate_failures do
        expect(bucket).to have_received(:create_file).with(*report.slice(:path, :gcs_path_latest).values, cache_control)
        expect(bucket).to have_received(:create_file).with(*history.slice(:path, :gcs_path_latest).values, cache_control)
      end
    end

    it "fetches and saves history info" do
      execute

      aggregate_failures do
        history_files.each do |f|
          expect(bucket).to have_received(:file).with("#{prefix}/history/#{f}")
          expect(file).to have_received(:download).with("#{common_info_path}/history/#{f}")
        end
      end
    end
  end

  context "with ci run" do
    include_context "with gitlab env"

    let(:report_url) { "https://storage.googleapis.com/bucket/project/#{run_id}/index.html" }
    let(:executor_info) { Publisher::Providers::Info::Gitlab.instance.executor(report_url) }

    before do
      allow(File).to receive(:write)

      allow(bucket).to receive(:file).with(history[:gcs_path_run]) { history[:file] }
      allow(bucket).to receive(:file).with(report[:gcs_path_run]) { report[:file] }
      allow(bucket).to receive(:files).with({ prefix: "#{prefix}/data" }) { [report[:existing_file]] }
    end

    it "uploads allure report" do
      execute

      aggregate_failures do
        history_files.each do |f|
          expect(bucket).to have_received(:file).with("#{prefix}/history/#{f}")
          expect(file).to have_received(:download).with("#{common_info_path}/history/#{f}")
        end

        expect(bucket).to have_received(:create_file).with(*history.slice(:path, :gcs_path_latest).values, cache_control)
        expect(bucket).to have_received(:create_file).with(*history.slice(:path, :gcs_path_run).values, cache_control)
        expect(bucket).to have_received(:create_file).with(*report.slice(:path, :gcs_path_run).values, cache_control)
      end
    end

    it "uploads latest allure report copy" do
      execute(copy_latest: true)

      expect(history[:file]).to have_received(:copy).with(history[:gcs_path_latest], force_copy_metadata: true)
      expect(report[:file]).to have_received(:copy).with(report[:gcs_path_latest], force_copy_metadata: true)
      expect(report[:existing_file]).to have_received(:delete)
    end

    it "adds executor info" do
      execute

      expect(File).to have_received(:write)
        .with("#{common_info_path}/executor.json", JSON.pretty_generate(executor_info)).twice
    end

    context "with default base url" do
      it "returns correct report urls" do
        expect(described_class.new(**args, copy_latest: true).report_urls).to eq({
          "Report url" => report_url,
          "Latest report url" => "https://storage.googleapis.com/bucket/project/index.html"
        })
      end
    end

    context "with custom base url" do
      let(:base_url) { "http://custom-url" }

      it "returns correct report urls" do
        expect(described_class.new(**args, copy_latest: true).report_urls).to eq({
          "Report url" => "#{base_url}/bucket/project/#{run_id}/index.html",
          "Latest report url" => "#{base_url}/bucket/project/index.html"
        })
      end
    end
  end
end
# rubocop:enable Layout/LineLength
