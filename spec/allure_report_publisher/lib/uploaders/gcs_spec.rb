require_relative "common_uploader"

RSpec.describe Publisher::Uploaders::GCS, epic: "uploaders" do
  include_context "with uploader"

  let(:client) { instance_double("Google::Cloud::Storage::Project", bucket: bucket) }
  let(:bucket) { instance_double("Google::Cloud::Storage::Bucket", file: file, create_file: nil) }
  let(:file) { instance_double("Google::Cloud::Storage::File", download: nil) }
  let(:history_run) { ["spec/fixture/fake_report/history/history.json", "#{prefix}/#{run_id}/history/history.json"] }
  let(:history) { ["spec/fixture/fake_report/history/history.json", "#{prefix}/history/history.json"] }
  let(:report_run) { ["spec/fixture/fake_report/index.html", "#{prefix}/#{run_id}/index.html"] }
  let(:report) { ["spec/fixture/fake_report/index.html", "#{prefix}/index.html"] }

  before do
    allow(Google::Cloud::Storage).to receive(:new) { client }
  end

  context "with non ci run" do
    it "generates allure report" do
      described_class.new(**args).execute

      aggregate_failures do
        expect(Publisher::ReportGenerator).to have_received(:new).with(results_glob)
        expect(report_generator).to have_received(:generate)
      end
    end

    it "uploads allure report" do
      described_class.new(**args).execute

      aggregate_failures do
        expect(bucket).to have_received(:create_file).with(*report)
        expect(bucket).to have_received(:create_file).with(*history)
      end
    end

    it "fetches and saves history info" do
      described_class.new(**args).execute

      aggregate_failures do
        history_files.each do |f|
          expect(bucket).to have_received(:file).with("#{prefix}/history/#{f}")
          expect(file).to have_received(:download).with("#{results_path}/history/#{f}")
        end
      end
    end
  end

  context "with ci run" do
    let(:ci_provider) { Publisher::Providers::Github }
    let(:ci_provider_instance) do
      instance_double("Publisher::Providers::Github", executor_info: executor_info, add_report_url: nil)
    end

    before do
      allow(File).to receive(:write)
      allow(Publisher::Providers::Github).to receive(:run_id).and_return(1)
      allow(Publisher::Providers::Github).to receive(:new) { ci_provider_instance }
    end

    it "uploads allure report" do
      described_class.new(**args).execute

      aggregate_failures do
        history_files.each do |f|
          expect(bucket).to have_received(:file).with("#{prefix}/history/#{f}")
          expect(file).to have_received(:download).with("#{results_path}/history/#{f}")
        end

        expect(bucket).to have_received(:create_file).with(*history)
        expect(bucket).to have_received(:create_file).with(*history_run)
        expect(bucket).to have_received(:create_file).with(*report_run)
      end
    end

    it "uploads latest allure report copy" do
      described_class.new(**{ **args, copy_latest: true }).execute

      expect(bucket).to have_received(:create_file).with(*report)
      expect(bucket).to have_received(:create_file).with(*report_run)
    end

    it "adds executor info" do
      described_class.new(**args).execute
      expect(File).to have_received(:write).with("#{results_path}/executor.json", executor_info.to_json)
    end

    it "updates pr description with allure report link" do
      described_class.new(**{ **args, update_pr: true }).execute
      expect(ci_provider_instance).to have_received(:add_report_url)
    end

    it "returns correct uploader report urls" do
      expect(described_class.new(**{ **args, copy_latest: true }).report_urls).to eq({
        "Report url" => "https://storage.googleapis.com/bucket/project/1/index.html",
        "Latest report url" => "https://storage.googleapis.com/bucket/project/index.html"
      })
    end
  end
end
