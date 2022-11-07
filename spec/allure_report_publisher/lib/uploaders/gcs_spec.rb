require_relative "common_uploader"

# rubocop:disable Layout/LineLength
RSpec.describe Publisher::Uploaders::GCS, epic: "uploaders" do
  include_context "with uploader"

  let(:client) { instance_double(Google::Cloud::Storage::Project, bucket: bucket) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket, create_file: nil, file: file) }
  let(:file) { instance_double(Google::Cloud::Storage::File, download: nil, copy: nil) }

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
      path: "spec/fixture/fake_report/index.html",
      gcs_path_run: "#{prefix}/#{run_id}/index.html",
      gcs_path_latest: "#{prefix}/index.html"
    }
  end

  def cache_control(max_age = 3600)
    { cache_control: "public, max-age=#{max_age}" }
  end

  before do
    allow(Google::Cloud::Storage).to receive(:new) { client }
  end

  context "with non ci run" do
    it "generates allure report" do
      described_class.new(**args).execute

      aggregate_failures do
        expect(Publisher::ReportGenerator).to have_received(:new).with(result_paths)
        expect(report_generator).to have_received(:generate)
      end
    end

    it "uploads allure report" do
      described_class.new(**args).execute

      aggregate_failures do
        expect(bucket).to have_received(:create_file).with(*report.slice(:path, :gcs_path_latest).values, cache_control)
        expect(bucket).to have_received(:create_file).with(*history.slice(:path, :gcs_path_latest).values, cache_control)
      end
    end

    it "fetches and saves history info" do
      described_class.new(**args).execute

      aggregate_failures do
        history_files.each do |f|
          expect(bucket).to have_received(:file).with("#{prefix}/history/#{f}")
          expect(file).to have_received(:download).with("#{common_info_path}/history/#{f}")
        end
      end
    end
  end

  context "with ci run" do
    let(:ci_provider) { Publisher::Providers::Github }
    let(:ci_provider_instance) do
      instance_double(Publisher::Providers::Github, executor_info: executor_info, add_result_summary: nil)
    end

    before do
      allow(File).to receive(:write)
      allow(Publisher::Providers::Github).to receive(:run_id).and_return(1)
      allow(Publisher::Providers::Github).to receive(:new) { ci_provider_instance }

      allow(bucket).to receive(:file).with(history[:gcs_path_run]) { history[:file] }
      allow(bucket).to receive(:file).with(report[:gcs_path_run]) { report[:file] }
    end

    it "uploads allure report" do
      described_class.new(**args).execute

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
      described_class.new(**{ **args, copy_latest: true }).execute

      expect(history[:file]).to have_received(:copy).with(history[:gcs_path_latest], force_copy_metadata: true)
      expect(report[:file]).to have_received(:copy).with(report[:gcs_path_latest], force_copy_metadata: true)
    end

    it "adds executor info" do
      described_class.new(**args).execute
      expect(File).to have_received(:write).with("#{common_info_path}/executor.json", executor_info.to_json)
    end

    it "updates pr description with allure report link" do
      described_class.new(**{ **args, update_pr: true }).execute
      expect(ci_provider_instance).to have_received(:add_result_summary)
    end

    it "returns correct uploader report urls" do
      expect(described_class.new(**{ **args, copy_latest: true }).report_urls).to eq({
        "Report url" => "https://storage.googleapis.com/bucket/project/1/index.html",
        "Latest report url" => "https://storage.googleapis.com/bucket/project/index.html"
      })
    end
  end
end
# rubocop:enable Layout/LineLength
