RSpec.shared_context "with uploader" do
  include_context "with mock helper"

  let(:report_generator) do
    instance_double(
      Publisher::ReportGenerator,
      generate: nil,
      common_info_path: common_info_path,
      report_path: report_path
    )
  end

  let(:result_paths) { ["spec/fixture/fake_results"] }
  let(:bucket_name) { "bucket" }
  let(:prefix) { "project" }
  let(:ci_provider) { nil }
  let(:run_id) { 1 }
  let(:executor_info) { { name: "Github" } }

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
      result_paths: result_paths,
      bucket: bucket_name,
      prefix: prefix,
      update_pr: false,
      copy_latest: false
    }
  end

  let(:common_info_path) { "spec/fixture/fake_results" }
  let(:report_path) { "spec/fixture/fake_report" }

  before do
    allow(Publisher::Providers).to receive(:provider) { ci_provider }
    allow(Publisher::ReportGenerator).to receive(:new) { report_generator }
  end
end
