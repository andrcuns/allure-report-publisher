RSpec.shared_context("with uploader") do
  include_context "with mock helper"

  let(:report_generator) { instance_double("Publisher::ReportGenerator", generate: nil) }
  let(:results_glob) { "spec/fixture/fake_results/*" }
  let(:bucket_name) { "bucket" }
  let(:prefix) { "project" }
  let(:ci_provider) { nil }
  let(:run_id) { 1 }
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
      bucket: bucket_name,
      prefix: prefix,
      update_pr: false,
      copy_latest: false
    }
  end

  let(:results_dir) { "spec/fixture/fake_results" }
  let(:report_dir) { "spec/fixture/fake_report" }

  before do
    allow(Publisher::Providers).to receive(:provider) { ci_provider }
    allow(Publisher::ReportGenerator).to receive(:new) { report_generator }

    allow(Dir).to receive(:mktmpdir).with("allure-results") { results_dir }
    allow(Dir).to receive(:mktmpdir).with("allure-report") { report_dir }
  end
end
