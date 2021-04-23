RSpec.describe Publisher::Uploaders::S3 do
  subject(:s3_uploader) { described_class.new(results_glob, bucket, project) }

  include_context "with mock helper"

  let(:report_generator) { instance_double("Publisher::ReportGenerator", generate: nil) }
  let(:s3_client) { instance_double("Aws::S3::Client", put_object: nil) }
  let(:results_glob) { "spec/fixture/fake_results/*" }
  let(:bucket) { "bucket" }
  let(:project) { "project" }

  let(:results_dir) { "spec/fixture/fake_results" }
  let(:report_dir) { "spec/fixture/fake_report" }

  before do
    allow(Publisher::ReportGenerator).to receive(:new) { report_generator }
    allow(Aws::S3::Client).to receive(:new) { s3_client }

    allow(Dir).to receive(:mktmpdir).with("allure-results") { results_dir }
    allow(Dir).to receive(:mktmpdir).with("allure-report") { report_dir }
  end

  it "generates and uploads allure report" do
    aggregate_failures do
      expect { s3_uploader.execute }.to output.to_stdout

      expect(report_generator).to have_received(:generate)
      expect(s3_client).to have_received(:put_object) do |arg|
        expect(arg[:body].path).to eq("spec/fixture/fake_report/index.html")
        expect(arg[:bucket]).to eq(bucket)
        expect(arg[:key]).to eq("#{project}/index.html")
      end
    end
  end
end
