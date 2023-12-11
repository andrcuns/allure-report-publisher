RSpec.describe Publisher::Providers::Info::Gitlab, epic: "providers" do
  subject(:pr) { described_class.instance.pr? }

  let(:mr_iid) { nil }
  let(:allure_project) { nil }
  let(:allure_mr_iid) { nil }

  let(:env) do
    {
      ALLURE_PROJECT_PATH: allure_project,
      ALLURE_MERGE_REQUEST_IID: allure_mr_iid,
      CI_MERGE_REQUEST_IID: mr_iid
    }
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end

  describe "#pr?" do
    context "with non merge request pipeline" do
      it { is_expected.to be(false) }
    end

    context "with merge request pipeline" do
      let(:mr_iid) { "1" }

      it { is_expected.to be(true) }
    end

    context "with custom project and mr iid" do
      let(:allure_project) { "custom/project" }
      let(:allure_mr_iid) { "1" }

      it { is_expected.to be(true) }
    end
  end
end
