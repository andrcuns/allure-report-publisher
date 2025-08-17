require_relative "common_uploader"
require_relative "../providers/github_env"

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
      body: File.read("spec/fixture/fake_report/history/history.json"),
      bucket: bucket_name,
      key: "#{prefix}/#{run_id}/history/history.json",
      content_type: "application/json",
      cache_control: "max-age=3600"
    }
  end

  let(:report_latest) { report_run.merge(key: "#{prefix}/index.html") }
  let(:report_run) do
    {
      body: File.read("spec/fixture/fake_report/index.html"),
      bucket: bucket_name,
      key: "#{prefix}/#{run_id}/index.html",
      content_type: "text/html",
      cache_control: "max-age=3600"
    }
  end

  def execute(allure_extra_args: [], **extra_args)
    uploader = described_class.new(**args, **extra_args)
    uploader.generate_report(allure_extra_args)
    uploader.upload
  end

  before do
    allow(Aws::S3::Client).to receive(:new).with({ region: "us-east-1", force_path_style: false }) { s3_client }
  end

  shared_examples "report generator" do
    it "generates allure report" do
      execute(allure_extra_args: ["--lang=en"])

      aggregate_failures do
        expect(Publisher::ReportGenerator).to have_received(:new).with(result_paths, report_name, report_path)
        expect(report_generator).to have_received(:generate).with(["--lang=en"])
      end
    end
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
      expect { execute }.to raise_error(<<~MSG.strip)
        missing aws credentials, provide credentials with one of the following options:
          - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
          - ~/.aws/credentials file
      MSG
    end
  end

  context "with non ci run" do
    around do |example|
      ClimateControl.modify(GITHUB_WORKFLOW: nil, GITLAB_CI: nil) { example.run }
    end

    context "without custom report name" do
      it_behaves_like "report generator"
    end

    context "with custom report name" do
      let(:report_name) { "custom_report_name" }

      it_behaves_like "report generator"
    end

    it "uploads allure report to s3" do
      execute

      expect(s3_client).to have_received(:put_object).with(report_latest)
    end

    it "fetches and saves history info" do
      execute

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
    include_context "with github env"

    let(:report_url) { "http://bucket.s3.amazonaws.com/project/#{run_id}/index.html" }
    let(:executor_info) { Publisher::Providers::Info::Github.instance.executor(report_url) }

    before do
      allow(s3_client).to receive(:list_objects_v2).with({ bucket: bucket_name, prefix: "#{prefix}/data" })
                                                   .and_return(existing_files)

      allow(File).to receive(:write)
    end

    it "uploads allure report to s3" do
      execute

      aggregate_failures do
        expect(s3_client).to have_received(:put_object).with(report_run)
        expect(s3_client).to have_received(:put_object).with(history_run)
        expect(s3_client).to have_received(:put_object).with(history_latest)
        expect(s3_client).not_to have_received(:put_object).with(report_latest)
      end
    end

    it "uploads latest allure report copy to s3" do
      execute(copy_latest: true)

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
      execute

      expect(File).to have_received(:write)
        .with("#{common_info_path}/executor.json", JSON.pretty_generate(executor_info)).twice
    end

    context "with default base url" do
      it "returns correct report urls" do
        expect(described_class.new(**args, copy_latest: true).report_urls).to eq({
          "Report url" => report_url,
          "Latest report url" => "http://bucket.s3.amazonaws.com/project/index.html"
        })
      end
    end

    context "with custom base url" do
      let(:base_url) { "http://custom-url" }

      it "returns correct report urls" do
        expect(described_class.new(**args, copy_latest: true).report_urls).to eq({
          "Report url" => "#{base_url}/project/#{run_id}/index.html",
          "Latest report url" => "#{base_url}/project/index.html"
        })
      end
    end

    context "with custom aws endpoint" do
      let(:custom_endpoint) { "http://custom-endpoint" }

      around do |example|
        ClimateControl.modify(AWS_ENDPOINT: custom_endpoint, AWS_FORCE_PATH_STYLE: "true") { example.run }
      end

      it "returns correct report urls" do
        expect(described_class.new(**args, copy_latest: true).report_urls).to eq({
          "Report url" => "#{custom_endpoint}/#{bucket_name}/project/#{run_id}/index.html",
          "Latest report url" => "#{custom_endpoint}/#{bucket_name}/project/index.html"
        })
      end
    end
  end
end
