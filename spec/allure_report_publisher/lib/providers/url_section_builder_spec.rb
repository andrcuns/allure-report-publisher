RSpec.describe Publisher::Providers::UrlSectionBuilder do
  subject(:builder) do
    described_class.new(
      report_url: report_url,
      report_path: report_path,
      build_name: build_name,
      sha_url: sha_url,
      summary_type: summary_type
    )
  end

  let(:report_url) { "https://report.com" }
  let(:build_name) { "build-name" }
  let(:sha_url) { "sha-url" }
  let(:report_path) { "report_path" }
  let(:summary_type) { nil }
  let(:summary_table) { nil }

  def jobs(jobs = [{ name: build_name, url: report_url, sha_url: sha_url }])
    markdowns = jobs.map do |job|
      name = job[:name]

      entry = ["<!-- #{name} -->"]
      entry << "**#{name}**: 📝 [test report](#{job[:url]}) for #{sha_url}"
      entry << "```markdown\n#{summary_table}\n```" if summary_type
      entry << "<!-- #{name} -->"

      entry.join("\n")
    end

    markdowns.join("\n")
  end

  def urls_section(job_section: jobs)
    <<~URLS.strip
      <!-- allure -->
      ---
      # Allure report
      `allure-report-publisher` generated test report!

      <!-- jobs -->
      #{job_section}
      <!-- jobs -->
      <!-- allurestop -->
    URLS
  end

  context "without prior result" do
    it "returns initial pr description" do
      expect(builder.updated_pr_description("pr")).to eq("pr\n\n#{urls_section}")
    end

    it "returns initial comment" do
      expect(builder.comment_body).to eq(urls_section.gsub("---\n", ""))
    end
  end

  context "with summary" do
    let(:summary_type) { Publisher::Helpers::Summary::BEHAVIORS }

    let(:summary_table) do
      table_style = {
        border_left: false,
        border_right: false,
        border_top: false,
        border_bottom: false,
        all_separators: true
      }
      summary_data = {
        "epic name" => { passed: 2, failed: 2, skipped: 1 },
        "epic name 2" => { passed: 1, failed: 0, skipped: 0 }
      }

      Terminal::Table.new(title: "#{summary_type} summary", style: table_style) do |table|
        table.headings = ["", "passed", "failed", "skipped", "result"]
        table.rows = summary_data.map do |name, summary|
          [name, *summary.values, summary[:failed].zero? ? "✅" : "❌"]
        end
      end
    end

    before do
      allow(Publisher::Helpers::Summary).to receive(:get) { summary_table }
    end

    it "return initial pr description with summary" do
      expect(builder.updated_pr_description("pr")).to eq("pr\n\n#{urls_section}")
      expect(Publisher::Helpers::Summary).to have_received(:get).with(report_path, summary_type)
    end

    it "returns initial comment with summary" do
      expect(builder.comment_body).to eq(urls_section.gsub("---\n", ""))
      expect(Publisher::Helpers::Summary).to have_received(:get).with(report_path, summary_type)
    end
  end

  context "with previous result for single job" do
    let(:existing_block) { urls_section(job_section: jobs([{ name: build_name, url: "old", sha_url: "old" }])) }

    it "updates existing job in pr description" do
      expect(builder.updated_pr_description("pr\n\n#{existing_block}")).to eq("pr\n\n#{urls_section}")
    end

    it "updates existing job in comment" do
      expect(builder.comment_body(existing_block)).to eq(urls_section.gsub("---\n", ""))
    end
  end

  context "with previous result for multiple jobs" do
    let(:existing_block) do
      urls_section(
        job_section: jobs([
          { name: "build-1", url: "test", sha_url: "old" },
          { name: "build-2", url: "test", sha_url: "old" }
        ])
      )
    end
    let(:result) do
      urls_section(
        job_section: jobs([
          { name: "build-1", url: "test", sha_url: sha_url },
          { name: "build-2", url: "test", sha_url: sha_url },
          { name: build_name, url: report_url, sha_url: sha_url }
        ])
      )
    end

    it "adds another job in pr description" do
      expect(builder.updated_pr_description("pr\n\n#{existing_block}")).to eq("pr\n\n#{result}")
    end

    it "adds another job in comment" do
      expect(builder.comment_body(existing_block)).to eq(result.gsub("---\n", ""))
    end
  end

  context "with content matcher" do
    it "matches existing url block" do
      expect(described_class.match?(urls_section)).to be(true)
    end

    it "doesnt match non url block" do
      expect(described_class.match?("some text")).to be(false)
    end
  end
end
