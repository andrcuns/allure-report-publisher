require "tempfile"

RSpec.shared_context "with gitlab env" do
  let(:mr_id) { 1 }
  let(:event_name) { "merge_request_event" }
  let(:custom_project) { nil }
  let(:custom_mr_id) { nil }
  let(:auth_token) { "token" }
  let(:run_id) { 123 }
  let(:sha) { "cfdef23b4b06df32ab1e98ee4091504948daf2a9" }

  let(:env) do
    {
      GITLAB_CI: "true",
      CI_SERVER_URL: "https://gitlab.com",
      CI_JOB_NAME: "test",
      CI_PIPELINE_ID: run_id.to_s,
      CI_PIPELINE_URL: "https://gitlab.com/pipeline/url",
      CI_PROJECT_PATH: "project",
      CI_MERGE_REQUEST_IID: mr_id.to_s,
      CI_PIPELINE_SOURCE: event_name,
      CI_MERGE_REQUEST_SOURCE_BRANCH_SHA: "",
      CI_COMMIT_SHA: sha,
      GITLAB_AUTH_TOKEN: auth_token,
      ALLURE_PROJECT_PATH: custom_project,
      ALLURE_MERGE_REQUEST_IID: custom_mr_id&.positive? ? custom_mr_id.to_s : nil
    }.compact
  end

  before do
    allow(Publisher::Providers).to receive_messages(
      provider: Publisher::Providers::Gitlab,
      info: Publisher::Providers::Info::Gitlab.instance
    )
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end
end
