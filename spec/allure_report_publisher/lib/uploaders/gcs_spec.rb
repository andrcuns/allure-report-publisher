require_relative "common_uploader"

RSpec.describe Publisher::Uploaders::GCS, epic: "uploaders" do
  include_context "with uploader"

  let(:client) { instance_double(Google::Cloud::Storage::Project, bucket: bucket) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket, file: file, create_file: nil) }
  let(:file) { instance_double(Google::Cloud::Storage::File, download: nil) }
  let(:gsutil) { instance_double(Publisher::Helpers::Gsutil, valid?: with_gsutil) }

  let(:report_path) { "spec/fixture/fake_report" }
  let(:history_run) { ["#{report_path}/history/history.json", "#{prefix}/#{run_id}/history/history.json"] }
  let(:history) { ["#{report_path}/history/history.json", "#{prefix}/history/history.json"] }
  let(:report_run) { ["#{report_path}/index.html", "#{prefix}/#{run_id}/index.html"] }
  let(:report) { ["#{report_path}/index.html", "#{prefix}/index.html"] }
  let(:with_gsutil) { false }

  def cache_control(max_age = 3600)
    { cache_control: "public, max-age=#{max_age}" }
  end

  before do
    allow(Google::Cloud::Storage).to receive(:new) { client }
    allow(Publisher::Helpers).to receive(:gsutil?).and_return(false)
    allow(Publisher::Helpers::Gsutil).to receive(:init).and_return(gsutil)
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
        expect(bucket).to have_received(:create_file).with(*report, cache_control)
        expect(bucket).to have_received(:create_file).with(*history, cache_control)
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
    end

    context "with gcs client" do
      it "uploads allure report" do
        described_class.new(**args).execute

        aggregate_failures do
          history_files.each do |f|
            expect(bucket).to have_received(:file).with("#{prefix}/history/#{f}")
            expect(file).to have_received(:download).with("#{common_info_path}/history/#{f}")
          end

          expect(bucket).to have_received(:create_file).with(*history, cache_control)
          expect(bucket).to have_received(:create_file).with(*history_run, cache_control)
          expect(bucket).to have_received(:create_file).with(*report_run, cache_control)
        end
      end

      it "uploads latest allure report copy" do
        described_class.new(**{ **args, copy_latest: true }).execute

        expect(bucket).to have_received(:create_file).with(*report, cache_control(60))
        expect(bucket).to have_received(:create_file).with(*report_run, cache_control)
      end
    end

    context "with gsutil" do
      let(:with_gsutil) { true }

      before do
        allow(gsutil).to receive(:batch_copy)
      end

      it "uploads allure report" do
        described_class.new(**args).execute

        aggregate_failures do
          history_files.each do |f|
            expect(bucket).to have_received(:file).with("#{prefix}/history/#{f}")
            expect(file).to have_received(:download).with("#{common_info_path}/history/#{f}")
          end

          expect(bucket).to have_received(:create_file).with(*history, cache_control)
          expect(gsutil).to have_received(:batch_copy).with(
            source_dir: report_path,
            destination_dir: "#{prefix}/#{run_id}",
            bucket: bucket_name,
            cache_control: 3600
          )
        end
      end

      it "uploads latest allure report copy" do
        described_class.new(**{ **args, copy_latest: true }).execute

        expect(gsutil).to have_received(:batch_copy).with(
          source_dir: report_path,
          destination_dir: prefix,
          bucket: bucket_name,
          cache_control: 60
        )
      end
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
