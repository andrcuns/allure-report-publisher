require "tempfile"

RSpec.shared_context "with github env" do
  let(:event_name) { "pull_request" }
  let(:auth_token) { "token" }
  let(:step_summary_file) { nil }
  let(:run_id) { "123" }
  let(:sha) { "cfdef23b4b06df32ab1e98ee4091504948daf2a9" }

  let(:env) do
    {
      GITHUB_WORKFLOW: "yes",
      GITHUB_SERVER_URL: "https://github.com",
      GITHUB_REPOSITORY: "andrcuns/allure-report-publisher",
      GITHUB_JOB: "test",
      GITHUB_RUN_ID: run_id,
      GITHUB_API_URL: "https://api.github.com",
      GITHUB_EVENT_PATH: "spec/fixture/workflow_event.json",
      GITHUB_STEP_SUMMARY: step_summary_file,
      GITHUB_AUTH_TOKEN: auth_token,
      GITHUB_EVENT_NAME: event_name
    }.compact
  end

  before do
    allow(Publisher::Providers).to receive_messages(
      provider: Publisher::Providers::Github,
      info: Publisher::Providers::Info::Github.instance
    )
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end
end
