RSpec.shared_examples "summary fetcher" do
  let(:report_path) { "spec/fixture/fake_report" }

  let(:summary_table) do
    Terminal::Table.new do |table|
      table.title = "#{summary_type || 'total'} summary"
      table.headings = ["", "passed", "failed", "skipped", "flaky", "result"]
      table.rows = rows
    end
  end

  it "fetches summary table", :aggregate_failures do
    expect(summary.status).to eq(status)
    expect(summary.table.to_s).to eq(summary_table.to_s)
  end
end

RSpec.describe Publisher::Helpers::Summary, epic: "helpers" do
  subject(:summary) { described_class.new(report_path, summary_type) }

  let(:status) { "❌" }

  context "with expanded summary" do
    let(:rows) do
      [
        ["epic name", 2, 2, 1, 1, "❌"],
        ["epic name 2", 1, 0, 0, 0, "✅"]
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
      let(:status) { "✅" }
      let(:rows) do
        [
          ["epic name", 4, 0, 1, 0, "✅"],
          ["epic name 2", 1, 0, 0, 0, "✅"]
        ]
      end

      it_behaves_like "summary fetcher"
    end
  end

  context "with short summary" do
    let(:summary_type) { Publisher::Helpers::Summary::TOTAL }
    let(:status) { "✅" }
    let(:rows) { [["Total", 5, 0, 1, 0, "✅"]] }

    context "with explicitly provided provided type" do
      it_behaves_like "summary fetcher"
    end

    context "without explicitly provided provided type" do
      let(:summary_type) { nil }

      it_behaves_like "summary fetcher"
    end
  end
end
