require "active_support"
require "active_support/testing/time_helpers"

RSpec.describe Publisher::ReportGenerator, epic: "generator" do
  include ActiveSupport::Testing::TimeHelpers

  subject(:report_generator) { described_class.new(result_paths) }

  include_context "with mock helper"

  let(:capture_status) { instance_double(Process::Status, success?: status) }

  let(:result_paths) { ["spec/fixture/fake_results"] }
  let(:common_info_dir) { "/common_info_results" }
  let(:report_dir) { File.join(tmpdir, "allure-report-#{Time.now.to_i}") }
  let(:status) { true }
  let(:tmpdir) { "/tmp/dir" }

  before do
    allow(Dir).to receive(:mktmpdir).with("allure-results") { common_info_dir }
    allow(Dir).to receive(:tmpdir) { tmpdir }
    allow(Open3).to receive(:capture3) { ["Allure output", "", capture_status] }
  end

  context "with present allure results" do
    let(:executors) { File.read("spec/fixture/fake_report/widgets/executors.json") }
    let(:deduped_executors) { [JSON.parse(executors).first].to_json }

    before do
      allow(File).to receive(:read).with("#{report_dir}/widgets/executors.json").and_return(executors)
      allow(File).to receive(:write).with("#{report_dir}/widgets/executors.json", deduped_executors)
    end

    it "generates allure report" do
      freeze_time do
        report_generator.generate

        expect(Open3).to have_received(:capture3).with(
          "allure generate --clean --output #{report_dir} #{common_info_dir} #{result_paths.join(' ')}"
        )
        expect(File).to have_received(:write).with("#{report_dir}/widgets/executors.json", deduped_executors)
      end
    end
  end

  context "with allure command failure" do
    let(:status) { false }
    let(:error_output) do
      <<~ERR.strip
        Command 'allure generate --clean --output #{report_dir} #{common_info_dir} #{result_paths.join(' ')}' failed!
        Out: Allure output
      ERR
    end

    it "exits with output of allure command" do
      freeze_time do
        expect { report_generator.generate }.to raise_error(error_output)
      end
    end
  end
end
