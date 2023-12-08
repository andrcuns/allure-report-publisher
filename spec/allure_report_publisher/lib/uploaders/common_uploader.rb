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
  let(:base_url) { nil }
  let(:ci_provider) { nil }
  let(:run_id) { "123" }

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
      base_url: base_url,
      copy_latest: false
    }
  end

  let(:common_info_path) { "spec/fixture/fake_results" }
  let(:report_path) { "spec/fixture/fake_report" }

  before do
    allow(Publisher::ReportGenerator).to receive(:new) { report_generator }
  end
end
