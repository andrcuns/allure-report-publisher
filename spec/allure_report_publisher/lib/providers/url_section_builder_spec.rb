RSpec.describe Publisher::Providers::UrlSectionBuilder do
  subject(:builder) { described_class.new(report_url: report_url, build_name: build_name, sha_url: sha_url) }

  let(:report_url) { "https://report.com" }
  let(:build_name) { "build-name" }
  let(:sha_url) { "sha-url" }

  def jobs(jobs = [{ name: build_name, url: report_url, sha_url: sha_url }])
    markdowns = jobs.map do |job|
      name = job[:name]

      <<~TXT.strip
        <!-- #{name} -->
        **#{name}**: 📝 [test report](#{job[:url]}) for #{sha_url}
        <!-- #{name} -->
      TXT
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
    let(:result) { urls_section }

    it "returns initial pr description" do
      expect(builder.updated_pr_description("pr")).to eq("pr\n\n#{result}")
    end

    it "returns initial comment" do
      expect(builder.comment_body).to eq(result.gsub("---\n", ""))
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
