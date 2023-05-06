require_relative "common_uploader"

RSpec.describe Publisher::Uploaders::S3, epic: "uploaders" do
  include_context "with uploader"
  include_context "with mock helper"

  let(:s3_client) do
    instance_double(
      Aws::S3::Client,
      get_object: nil,
      put_object: nil,
      copy_object: nil,
      list_objects_v2: nil,
      delete_objects: nil
    )
  end

  let(:existing_file) { "file" }
  let(:existing_files) do
    [
      double("objects", contents: [double("object", key: existing_file)])
    ]
  end

  let(:history_latest) { history_run.merge(key: "#{prefix}/history/history.json") }
  let(:history_run) do
    {
      body: File.new("spec/fixture/fake_report/history/history.json"),
      bucket: bucket_name,
      key: "#{prefix}/1/history/history.json",
      content_type: "application/json",
      cache_control: "max-age=3600"
    }
  end

  let(:report_latest) { report_run.merge(key: "#{prefix}/index.html") }
  let(:report_run) do
    {
      body: File.new("spec/fixture/fake_report/index.html"),
      bucket: bucket_name,
      key: "#{prefix}/1/index.html",
      content_type: "text/html",
      cache_control: "max-age=3600"
    }
  end

  before do
    allow(Aws::S3::Client).to receive(:new).with({ region: "us-east-1", force_path_style: false }) { s3_client }
    allow(File).to receive(:new).and_call_original
    allow(File).to receive(:new).with(Pathname.new(history_latest[:body].path)) { history_latest[:body] }
    allow(File).to receive(:new).with(Pathname.new(report_latest[:body].path)) { report_latest[:body] }
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
      expect { described_class.new(**args).execute }.to raise_error(<<~MSG.strip)
        missing aws credentials, provide credentials with one of the following options:
          - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
          - ~/.aws/credentials file
      MSG
    end
  end

  context "with non ci run" do
    it "generates allure report" do
      described_class.new(**args).execute

      aggregate_failures do
        expect(Publisher::ReportGenerator).to have_received(:new).with(result_paths)
        expect(report_generator).to have_received(:generate)
      end
    end

    it "uploads allure report to s3" do
      described_class.new(**args).execute

      expect(s3_client).to have_received(:put_object).with(report_latest)
    end

    it "fetches and saves history info" do
      described_class.new(**args).execute

      aggregate_failures do
        history_files.each do |file|
          expect(s3_client).to have_received(:get_object).with(
            response_target: "#{common_info_path}/history/#{file}",
            key: "#{prefix}/history/#{file}",
            bucket: bucket_name
          )
        end
        expect(s3_client).to have_received(:put_object).with(history_latest)
      end
    end
  end

  context "with ci run" do
    let(:ci_provider) { Publisher::Providers::Github }
    let(:ci_provider_instance) do
      instance_double(Publisher::Providers::Github, executor_info: executor_info, add_result_summary: nil)
    end

    before do
      allow(Publisher::Providers::Github).to receive(:run_id).and_return(1)
      allow(Publisher::Providers::Github).to receive(:new) { ci_provider_instance }

      allow(s3_client).to receive(:list_objects_v2).with({ bucket: bucket_name, prefix: "#{prefix}/data" })
                                                   .and_return(existing_files)

      allow(File).to receive(:write)
      allow(File).to receive(:new).with(Pathname.new(history_run[:body].path)) { history_run[:body] }
      allow(File).to receive(:new).with(Pathname.new(report_run[:body].path)) { report_run[:body] }
    end

    it "uploads allure report to s3" do
      described_class.new(**args).execute

      aggregate_failures do
        expect(s3_client).to have_received(:put_object).with(report_run)
        expect(s3_client).to have_received(:put_object).with(history_run)
        expect(s3_client).to have_received(:put_object).with(history_latest)
        expect(s3_client).not_to have_received(:put_object).with(report_latest)
      end
    end

    it "uploads latest allure report copy to s3" do
      described_class.new(**args, copy_latest: true).execute

      aggregate_failures do
        expect(s3_client).to have_received(:put_object).with(report_run)
        expect(s3_client).to have_received(:put_object).with(history_run)

        expect(s3_client).to have_received(:delete_objects).with({
          bucket: bucket_name,
          delete: { objects: [{ key: existing_file }] }
        })
        expect(s3_client).to have_received(:copy_object).with({
          bucket: bucket_name,
          copy_source: "/#{bucket_name}/#{report_run[:key]}",
          key: report_latest[:key],
          metadata_directive: "REPLACE",
          content_type: "text/html",
          cache_control: "max-age=60"
        })
        expect(s3_client).to have_received(:copy_object).with({
          bucket: bucket_name,
          copy_source: "/#{bucket_name}/#{history_run[:key]}",
          key: history_latest[:key],
          metadata_directive: "REPLACE",
          content_type: "application/json",
          cache_control: "max-age=60"
        })
      end
    end

    it "adds executor info" do
      described_class.new(**args).execute
      expect(File).to have_received(:write).with("#{common_info_path}/executor.json", executor_info.to_json)
    end

    it "updates pr description with allure report link" do
      described_class.new(**args, update_pr: true).execute
      expect(ci_provider_instance).to have_received(:add_result_summary)
    end

    context "with default base url" do
      it "returns correct report urls" do
        expect(described_class.new(**args, copy_latest: true).report_urls).to eq({
          "Report url" => "http://bucket.s3.amazonaws.com/project/1/index.html",
          "Latest report url" => "http://bucket.s3.amazonaws.com/project/index.html"
        })
      end
    end

    context "with custom base url" do
      let(:base_url) { "http://custom-url" }

      it "returns correct report urls" do
        expect(described_class.new(**args, copy_latest: true).report_urls).to eq({
          "Report url" => "#{base_url}/project/1/index.html",
          "Latest report url" => "#{base_url}/project/index.html"
        })
      end
    end
  end
end
