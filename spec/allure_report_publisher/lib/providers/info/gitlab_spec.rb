RSpec.describe Publisher::Providers::Info::Gitlab, epic: "providers" do
  subject(:pr) { described_class.instance.pr? }

  let(:allure_project) { nil }
  let(:allure_mr_iid) { nil }
  let(:pipeline_source) { "push" }

  let(:env) do
    {
      ALLURE_PROJECT_PATH: allure_project,
      ALLURE_MERGE_REQUEST_IID: allure_mr_iid,
      CI_PIPELINE_SOURCE: pipeline_source
    }
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end

  describe "#pr?" do
    context "with push event" do
      it { is_expected.to be(false) }
    end

    context "with merge request event" do
      let(:pipeline_source) { "merge_request_event" }

      it { is_expected.to be(true) }
    end

    context "with custom project and mr iid" do
      let(:allure_project) { "custom/project" }
      let(:allure_mr_iid) { "1" }

      it { is_expected.to be(true) }
    end
  end
end
