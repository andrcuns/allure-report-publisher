RSpec.describe Publisher::Providers::UrlSectionBuilder do
  subject(:builder) { described_class.new(report_url: report_url, build_name: build_name, sha_url: sha_url) }

  let(:report_url) { "https://report.com" }
  let(:build_name) { "build-name" }
  let(:sha_url) { "sha url" }

  def urls_section(url_sha: sha_url, job_name: build_name, url_report: report_url)
    <<~URLS.strip
      <!-- allure -->
      ---
      # Allure report
      `allure-report-publisher` generated allure report for #{url_sha}!

      <!-- jobs -->
      **#{job_name}**: 📝 [allure report](#{url_report})<br />
      <!-- jobs -->
      <!-- allurestop -->
    URLS
  end

  context "with pr description update" do
    it "returns initial pr description" do
      expect(builder.updated_pr_description("pr")).to eq("pr\n\n#{urls_section}")
    end

    it "returns updated pr description" do
      expect(builder.updated_pr_description(urls_section(url_report: "older-report"))).to eq(urls_section)
    end

    it "adds second job" do
      expect(builder.updated_pr_description(urls_section(job_name: "build-name-2"))).to eq(<<~PR.strip)
        <!-- allure -->
        ---
        # Allure report
        `allure-report-publisher` generated allure report for #{sha_url}!

        <!-- jobs -->
        **build-name-2**: 📝 [allure report](#{report_url})<br />
        **#{build_name}**: 📝 [allure report](#{report_url})<br />
        <!-- jobs -->
        <!-- allurestop -->
      PR
    end
  end

  context "with pr comment update" do
    it "returns initial comment" do
      expect(builder.comment_body).to eq(urls_section.gsub("---\n", ""))
    end

    it "returns updated pr description" do
      expect(builder.comment_body(urls_section(url_report: "older-report"))).to eq(urls_section.gsub("---\n", ""))
    end

    it "adds second job" do
      expect(builder.comment_body(urls_section(job_name: "build-name-2"))).to eq(<<~PR.strip)
        <!-- allure -->
        # Allure report
        `allure-report-publisher` generated allure report for #{sha_url}!

        <!-- jobs -->
        **build-name-2**: 📝 [allure report](#{report_url})<br />
        **#{build_name}**: 📝 [allure report](#{report_url})<br />
        <!-- jobs -->
        <!-- allurestop -->
      PR
    end
  end

  context "with content matcher" do
    it "matches existing url block" do
      expect(described_class.match?(urls_section)).to eq(true)
    end

    it "doesnt match non url block" do
      expect(described_class.match?("some text")).to eq(false)
    end
  end
end
