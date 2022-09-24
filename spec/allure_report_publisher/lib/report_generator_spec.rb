RSpec.describe Publisher::ReportGenerator, epic: "generator" do
  subject(:report_generator) { described_class.new(results_glob) }

  include_context "with mock helper"

  let(:capture_status) { instance_double(Process::Status, success?: status) }

  let(:results_glob) { "spec/fixture/fake_results" }
  let(:results_dir) { "/results_dir" }
  let(:report_dir) { "/report_dir" }
  let(:status) { true }

  before do
    allow(Dir).to receive(:mktmpdir).with("allure-results") { results_dir }
    allow(Dir).to receive(:mktmpdir).with("allure-report") { report_dir }
    allow(Open3).to receive(:capture3) { ["Allure output", "", capture_status] }
  end

  context "with present allure results" do
    it "generates allure report" do
      aggregate_failures do
        report_generator.generate

        expect(Open3).to have_received(:capture3).with(
          "allure generate --clean --output #{report_dir} #{results_dir} #{results_glob}"
        )
      end
    end
  end

  context "with empty allure results" do
    let(:results_glob) { "spec/*.tar.gz" }

    it "exits with missing allure results message" do
      expect { report_generator.generate }.to raise_error("Missing allure results")
    end
  end

  context "with allure command failure" do
    let(:status) { false }

    it "exits with output of allure command" do
      expect { report_generator.generate }.to raise_error("Allure output")
    end
  end
end
