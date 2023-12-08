require "tempfile"

RSpec.shared_context "with gitlab env" do
  let(:mr_id) { "1" }
  let(:event_name) { "merge_request_event" }
  let(:custom_project) { nil }
  let(:custom_mr_id) { nil }
  let(:auth_token) { "token" }
  let(:run_id) { "123" }

  let(:env) do
    {
      GITLAB_CI: "yes",
      CI_SERVER_URL: "https://gitlab.com",
      CI_JOB_NAME: "test",
      CI_PIPELINE_ID: run_id,
      CI_PIPELINE_URL: "https://gitlab.com/pipeline/url",
      CI_PROJECT_PATH: "project",
      CI_MERGE_REQUEST_IID: mr_id,
      CI_PIPELINE_SOURCE: event_name,
      CI_MERGE_REQUEST_SOURCE_BRANCH_SHA: "",
      CI_COMMIT_SHA: sha,
      GITLAB_AUTH_TOKEN: auth_token,
      ALLURE_PROJECT_PATH: custom_project,
      ALLURE_MERGE_REQUEST_IID: custom_mr_id
    }.compact
  end

  before do
    allow(Publisher::Providers::Info::Gitlab).to receive(:instance)
      .and_return(Publisher::Providers::Info::Gitlab.send(:new))
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end
end
