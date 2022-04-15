RSpec.shared_examples "summary fetcher" do
  let(:report_path) { "spec/fixture/fake_report" }

  let(:summary_table) do
    Terminal::Table.new do |table|
      table.title = "#{summary_type} summary"
      table.headings = ["", "passed", "failed", "skipped", "result"]
      table.rows = rows
    end
  end

  it "fetches summary table" do
    expect(summary.to_s).to eq(summary_table.to_s)
  end
end

RSpec.describe Publisher::Helpers::Summary, epic: "helpers" do
  subject(:summary) { described_class.get(report_path, summary_type) }

  context "with expanded summary" do
    let(:rows) do
      [
        ["epic name", 2, 2, 1, "❌"],
        ["epic name 2", 1, 0, 0, "✅"]
      ]
    end

    context "with behavior summary" do
      let(:summary_type) { Publisher::Helpers::Summary::BEHAVIORS }

      it_behaves_like "summary fetcher"
    end

    context "with packages summary" do
      let(:summary_type) { Publisher::Helpers::Summary::PACKAGES }

      it_behaves_like "summary fetcher"
    end

    context "with suites summary" do
      let(:summary_type) { Publisher::Helpers::Summary::SUITES }

      it_behaves_like "summary fetcher"
    end
  end

  context "with total summary" do
    let(:summary_type) { Publisher::Helpers::Summary::TOTAL }
    let(:rows) { [["Total", 3, 2, 1, "❌"]] }

    it_behaves_like "summary fetcher"
  end
end
