require "tempfile"

RSpec.shared_context "with github env" do
  let(:event_name) { "pull_request" }
  let(:step_summary_file) { nil }

  let(:env) do
    {
      GITHUB_WORKFLOW: "yes",
      GITHUB_SERVER_URL: "https://github.com",
      GITHUB_REPOSITORY: "andrcuns/allure-report-publisher",
      GITHUB_JOB: "test",
      GITHUB_RUN_ID: "123",
      GITHUB_API_URL: "https://api.github.com",
      GITHUB_EVENT_PATH: "spec/fixture/workflow_event.json",
      GITHUB_STEP_SUMMARY: step_summary_file,
      GITHUB_AUTH_TOKEN: auth_token,
      GITHUB_EVENT_NAME: event_name
    }.compact
  end

  before do
    allow(Publisher::Providers::Info::Github).to receive(:instance)
      .and_return(Publisher::Providers::Info::Github.send(:new))
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end
end
