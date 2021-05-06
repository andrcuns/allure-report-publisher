require_relative "./common_uploader"

RSpec.describe Publisher::Uploaders::GCS do
  include_context "with uploader"

  let(:report_generator) { instance_double("Publisher::ReportGenerator", generate: nil) }
  let(:client) { instance_double("Google::Cloud::Storage::Project", bucket: bucket) }
  let(:bucket) { instance_double("Google::Cloud::Storage::Bucket", file: file, create_file: nil) }
  let(:file) { instance_double("Google::Cloud::Storage::File", download: nil) }
  let(:history_run) { ["spec/fixture/fake_report/history/history.json", "#{prefix}/#{run_id}/history/history.json"] }
  let(:history) { ["spec/fixture/fake_report/history/history.json", "#{prefix}/history/history.json"] }
  let(:report_run) { ["spec/fixture/fake_report/index.html", "#{prefix}/#{run_id}/index.html"] }
  let(:report) { ["spec/fixture/fake_report/index.html", "#{prefix}/index.html"] }

  before do
    allow(Publisher::Providers).to receive(:provider) { ci_provider }
    allow(Publisher::ReportGenerator).to receive(:new) { report_generator }
    allow(Google::Cloud::Storage).to receive(:new) { client }

    allow(Dir).to receive(:mktmpdir).with("allure-results") { results_dir }
    allow(Dir).to receive(:mktmpdir).with("allure-report") { report_dir }
  end

  context "with non ci run" do
    it "generates allure report" do
      described_class.new(**args).execute

      aggregate_failures do
        expect(Publisher::ReportGenerator).to have_received(:new).with(results_glob, results_dir, report_dir)
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
          expect(file).to have_received(:download).with("#{results_dir}/history/#{f}")
        end
      end
    end
  end

  context "with ci run" do
    let(:ci_provider) { Publisher::Providers::Github }
    let(:ci_provider_instance) do
      instance_double("Publisher::Providers::Github", write_executor_info: nil, add_report_url: nil)
    end

    before do
      allow(Publisher::Providers::Github).to receive(:run_id).and_return(1)
      allow(Publisher::Providers::Github).to receive(:new) { ci_provider_instance }
    end

    it "uploads allure report" do
      described_class.new(**args).execute

      aggregate_failures do
        history_files.each do |f|
          expect(bucket).to have_received(:file).with("#{prefix}/history/#{f}")
          expect(file).to have_received(:download).with("#{results_dir}/history/#{f}")
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
      expect(ci_provider_instance).to have_received(:write_executor_info)
    end

    it "updates pr description with allure report link" do
      described_class.new(**{ **args, update_pr: true }).execute
      expect(ci_provider_instance).to have_received(:add_report_url)
    end
  end
end