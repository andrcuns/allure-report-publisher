RSpec.shared_examples "summary fetcher" do
  let(:report_path) { "spec/fixture/fake_report" }

  let(:summary_data) do
    {
      "epic name" => { passed: 2, failed: 2, skipped: 1 },
      "epic name 2" => { passed: 1, failed: 0, skipped: 0 }
    }
  end

  let(:table_style) do
    {
      border_left: false,
      border_right: false,
      border_top: false,
      border_bottom: false,
      all_separators: true
    }
  end

  let(:summary_table) do
    Terminal::Table.new(title: "#{summary_type} summary", style: table_style) do |table|
      table.headings = ["", "passed", "failed", "skipped", "result"]
      table.rows = summary_data.map do |name, summary|
        [name, *summary.values, summary[:failed].zero? ? "✅" : "❌"]
      end
    end
  end

  it "fetches summary table" do
    expect(summary.to_s).to eq(summary_table.to_s)
  end
end

RSpec.describe Publisher::Helpers::Summary, epic: "helpers" do
  subject(:summary) { described_class.get(report_path, summary_type) }

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
