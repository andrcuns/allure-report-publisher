RSpec.describe Publisher::Providers::UrlSectionBuilder do
  subject(:builder) { described_class.new(report_url: report_url, build_name: build_name, sha_url: sha_url) }

  let(:report_url) { "https://report.com" }
  let(:build_name) { "build-name" }
  let(:sha_url) { "sha url" }

  def jobs(jobs = [{ name: build_name, url: report_url }])
    jobs.map { |job| "**#{job[:name]}**: 📝 [allure test report](#{job[:url]})<br />" }.join("\n")
  end

  def urls_section(url_sha: sha_url, job_section: jobs)
    <<~URLS.strip
      <!-- allure -->
      ---
      # Allure report
      `allure-report-publisher` generated allure test report for #{url_sha}!

      <!-- jobs -->
      #{job_section}
      <!-- jobs -->
      <!-- allurestop -->
    URLS
  end

  context "with pr description update" do
    it "returns initial pr description" do
      expect(builder.updated_pr_description("pr")).to eq("pr\n\n#{urls_section}")
    end

    it "updates existing job" do
      pr_desc = urls_section(url_sha: "old", job_section: jobs([{ name: build_name, url: "old" }]))
      expect(builder.updated_pr_description(pr_desc)).to eq(urls_section)
    end

    it "adds another job" do
      pr_desc = urls_section(
        url_sha: "old",
        job_section: jobs([
          { name: "build-1", url: "test" },
          { name: "build-2", url: "test" }
        ])
      )
      expect(builder.updated_pr_description(pr_desc)).to eq(
        urls_section(
          job_section: jobs([
            { name: "build-1", url: "test" },
            { name: "build-2", url: "test" },
            { name: build_name, url: report_url }
          ])
        )
      )
    end
  end

  context "with pr comment update" do
    it "returns initial comment" do
      expect(builder.comment_body).to eq(urls_section.gsub("---\n", ""))
    end

    it "updates existing job" do
      comment = urls_section(url_sha: "old", job_section: jobs([{ name: build_name, url: "old" }]))
      expect(builder.comment_body(comment)).to eq(urls_section.gsub("---\n", ""))
    end

    it "adds another job" do
      comment = urls_section(
        url_sha: "old",
        job_section: jobs([
          { name: "build-1", url: "test" },
          { name: "build-2", url: "test" }
        ])
      )
      expect(builder.comment_body(comment)).to eq(
        urls_section(
          job_section: jobs([
            { name: "build-1", url: "test" },
            { name: "build-2", url: "test" },
            { name: build_name, url: report_url }
          ])
        ).gsub("---\n", "")
      )
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
