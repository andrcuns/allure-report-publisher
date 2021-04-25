RSpec.describe Publisher::CI do
  subject(:ci_provider) { Publisher::CI.provider.new(results_path, report_url) } # rubocop:disable RSpec/DescribedClass

  let(:results_path) { Dir.mktmpdir("allure-results", "tmp") }
  let(:report_url) { "https://report.com" }

  context Publisher::CI::GithubActions do
    let(:env) do
      {
        GITHUB_WORKFLOW: "yes",
        GITHUB_SERVER_URL: "https://github.com",
        GITHUB_REPOSITORY: "andrcuns/allure-report-publisher",
        GITHUB_JOB: "test",
        GITHUB_RUN_ID: "123",
        GITHUB_RUN_NUMBER: "1"
      }
    end

    around do |example|
      ClimateControl.modify(env) { example.run }
    end

    it "creates executor.json file" do
      ci_provider.write_executor_info

      expect(JSON.parse(File.read("#{results_path}/executor.json"), symbolize_names: true)).to eq(
        {
          name: "Github",
          type: "github",
          reportName: "AllureReport",
          url: env[:GITHUB_SERVER_URL],
          reportUrl: report_url,
          buildUrl: "#{env[:GITHUB_SERVER_URL]}/#{env[:GITHUB_REPOSITORY]}/actions/runs/#{env[:GITHUB_RUN_ID]}",
          buildOrder: env[:GITHUB_RUN_NUMBER],
          buildName: env[:GITHUB_JOB]
        }
      )
    end
  end
end
