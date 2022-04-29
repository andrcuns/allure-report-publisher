RSpec.shared_examples "summary fetcher" do |summary_table_style|
  subject(:summary) { described_class.new(report_path, summary_type, summary_table_style) }

  let(:report_path) { "spec/fixture/fake_report" }
  let(:markdown) { summary_table_style == :markdown }

  let(:summary_table) do
    terminal_table = Terminal::Table.new do |table|
      table.title = "#{summary_type || 'total'} summary" unless markdown
      table.style = { border: summary_table_style }
      table.headings = ["", "passed", "failed", "skipped", "flaky", "result"]
      rows.call(table)
    end

    summary_table_style == :ascii ? "```markdown\n#{terminal_table}\n```" : terminal_table.to_s
  end

  it "fetches #{summary_table_style} summary table", :aggregate_failures do
    expect(summary.status).to eq(status)
    expect(summary.table).to eq(summary_table.to_s)
  end
end

RSpec.describe Publisher::Helpers::Summary, epic: "helpers" do
  context "with expanded summary" do
    context "with behavior summary" do
      let(:summary_type) { Publisher::Helpers::Summary::BEHAVIORS }
      let(:status) { "❌" }

      let(:rows) do
        lambda do |table|
          [["epic name", 2, 2, 1, 1, "❌"], ["epic name 2", 1, 0, 0, 0, "✅"]].each { |row| table << row }
          table << :separator
          table << ["Total", 3, 2, 1, 1, "❌"]
        end
      end

      it_behaves_like "summary fetcher", :ascii
      it_behaves_like "summary fetcher", :markdown
    end

    context "with packages summary" do
      let(:summary_type) { Publisher::Helpers::Summary::PACKAGES }
      let(:status) { "❗" }

      let(:rows) do
        lambda do |table|
          [["epic name", 4, 0, 1, 0, "✅"], ["epic name 2", 1, 0, 0, 1, "❗"]].each { |row| table << row }
          table << :separator
          table << ["Total", 5, 0, 1, 1, "❗"]
        end
      end

      it_behaves_like "summary fetcher", :ascii
      it_behaves_like "summary fetcher", :markdown
    end

    context "with suites summary" do
      let(:summary_type) { Publisher::Helpers::Summary::SUITES }
      let(:status) { "✅" }

      let(:rows) do
        lambda do |table|
          [["epic name", 4, 0, 1, 0, "✅"], ["epic name 2", 1, 0, 0, 0, "✅"]].each { |row| table << row }
          table << :separator
          table << ["Total", 5, 0, 1, 0, "✅"]
        end
      end

      it_behaves_like "summary fetcher", :ascii
      it_behaves_like "summary fetcher", :markdown
    end
  end

  context "with short summary" do
    let(:summary_type) { Publisher::Helpers::Summary::TOTAL }
    let(:status) { "✅" }

    let(:rows) do
      ->(table) { table << ["Total", 5, 0, 1, 0, "✅"] }
    end

    context "with explicitly provided provided type" do
      it_behaves_like "summary fetcher", :ascii
      it_behaves_like "summary fetcher", :markdown
    end

    context "without explicitly provided provided type" do
      let(:summary_type) { nil }

      it_behaves_like "summary fetcher", :ascii
      it_behaves_like "summary fetcher", :markdown
    end
  end
end
