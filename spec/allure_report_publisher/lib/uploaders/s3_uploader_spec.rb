RSpec.describe Publisher::Uploaders::S3 do
  subject(:s3_uploader) { described_class }

  include_context "with mock helper"
  include_context "with stdout capture"

  let(:report_generator) { instance_double("Publisher::ReportGenerator", generate: nil) }
  let(:s3_client) { instance_double("Aws::S3::Client", get_object: nil) }
  let(:ci_provider) { nil }
  let(:results_glob) { "spec/fixture/fake_results/*" }
  let(:bucket) { "bucket" }
  let(:prefix) { "project" }
  let(:put_object_args) { [] }
  let(:history_files) do
    [
      "categories-trend.json",
      "duration-trend.json",
      "history-trend.json",
      "history.json",
      "retry-trend.json"
    ]
  end
  let(:args) do
    {
      results_glob: results_glob,
      bucket: bucket,
      prefix: prefix,
      update_pr: false,
      copy_latest: false
    }
  end
  let(:run_report_files) do
    [
      {
        body: "spec/fixture/fake_report/history/history.json",
        bucket: bucket,
        key: "#{prefix}/1/history/history.json"
      },
      {
        body: "spec/fixture/fake_report/index.html",
        bucket: bucket,
        key: "#{prefix}/1/index.html"
      }
    ]
  end
  let(:latest_report_files) do
    [
      {
        body: "spec/fixture/fake_report/index.html",
        bucket: bucket,
        key: "#{prefix}/index.html"
      }
    ]
  end

  let(:results_dir) { "spec/fixture/fake_results" }
  let(:report_dir) { "spec/fixture/fake_report" }

  before do
    allow(Publisher::Providers).to receive(:provider) { ci_provider }
    allow(Publisher::ReportGenerator).to receive(:new) { report_generator }
    allow(Aws::S3::Client).to receive(:new) { s3_client }
    allow(s3_client).to receive(:put_object) do |arg|
      put_object_args.push({
        body: arg[:body].path,
        bucket: arg[:bucket],
        key: arg[:key]
      })
    end

    allow(Dir).to receive(:mktmpdir).with("allure-results") { results_dir }
    allow(Dir).to receive(:mktmpdir).with("allure-report") { report_dir }
  end

  context "with missing aws credentials" do
    let(:err_msg) do
      Pastel.new(enabled: true).decorate(<<~MSG.strip, :red)
        missing aws credentials, provide credentials with one of the following options:
          - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
          - ~/.aws/credentials file
      MSG
    end

    before do
      allow(Aws::S3::Client).to receive(:new).and_raise(Aws::Sigv4::Errors::MissingCredentialsError)
    end

    it "exits with custom credentials missing error" do
      expect do
        expect { s3_uploader.new(**args).execute }.to raise_error(SystemExit)
      end.to output("#{err_msg}\n").to_stderr
    end
  end

  context "with non ci run" do
    it "generates allure report" do
      aggregate_failures do
        s3_uploader.new(**args).execute

        expect(Publisher::ReportGenerator).to have_received(:new).with(results_glob, results_dir, report_dir)
        expect(report_generator).to have_received(:generate)
      end
    end

    it "uploads allure report to s3" do
      aggregate_failures do
        s3_uploader.new(**args).execute

        expect(put_object_args).to include(
          {
            body: "spec/fixture/fake_report/history/history.json",
            bucket: bucket,
            key: "#{prefix}/history/history.json"
          },
          {
            body: "spec/fixture/fake_report/index.html",
            bucket: bucket,
            key: "#{prefix}/index.html"
          }
        )
      end
    end

    it "fetches and saves history info" do
      aggregate_failures do
        s3_uploader.new(**args).execute

        history_files.each do |file|
          expect(s3_client).to have_received(:get_object).with(
            response_target: "#{results_dir}/history/#{file}",
            key: "#{prefix}/history/#{file}",
            bucket: bucket
          )
        end
        expect(put_object_args).to include({
          body: "spec/fixture/fake_report/history/history.json",
          bucket: bucket,
          key: "#{prefix}/history/history.json"
        })
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

    it "uploads allure report to s3" do
      s3_uploader.new(**args).execute

      aggregate_failures do
        expect(put_object_args).to include(*run_report_files)
        expect(put_object_args).not_to include(*latest_report_files)
      end
    end

    it "uploads latest allure report copy to s3" do
      s3_uploader.new(**{ **args, copy_latest: true }).execute

      expect(put_object_args).to include(*latest_report_files)
    end

    it "adds executor info" do
      s3_uploader.new(**args).execute
      expect(ci_provider_instance).to have_received(:write_executor_info)
    end

    it "updates pr description with allure report link" do
      s3_uploader.new(**{ **args, update_pr: true }).execute
      expect(ci_provider_instance).to have_received(:add_report_url)
    end
  end
end
