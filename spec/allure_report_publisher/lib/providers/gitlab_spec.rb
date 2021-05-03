RSpec.describe Publisher::Providers::Gitlab do
  subject(:provider) { described_class.new(results_path, report_url) }

  let(:results_path) { Dir.mktmpdir("allure-results", "tmp") }
  let(:report_url) { "https://report.com" }
  let(:auth_token) { "token" }
  let(:event_name) { "pull_request" }

  let(:env) do
    {
      GITLAB_CI: "yes",
      CI_SERVER_URL: "https://gitlab.com",
      CI_PROJECT_PATH: "andrcuns/allure-report-publisher",
      CI_JOB_NAME: "test",
      CI_PIPELINE_ID: "123",
      CI_PIPELINE_URL: "https://gitlab.com/pipeline/url"
    }.compact
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end

  context "when adding executor info" do
    it "creates correct executor.json file" do
      provider.write_executor_info

      expect(JSON.parse(File.read("#{results_path}/executor.json"), symbolize_names: true)).to eq(
        {
          name: "Gitlab",
          type: "gitlab",
          reportName: "AllureReport",
          url: env[:CI_SERVER_URL],
          reportUrl: report_url,
          buildUrl: env[:CI_PIPELINE_URL],
          buildOrder: env[:CI_PIPELINE_ID],
          buildName: env[:CI_JOB_NAME]
        }
      )
    end
  end
end
