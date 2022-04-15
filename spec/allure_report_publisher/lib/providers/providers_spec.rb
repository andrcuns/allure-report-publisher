RSpec.describe Publisher::Providers, epic: "providers" do
  subject(:provider) { described_class.provider }

  it "detects github instance" do
    ClimateControl.modify(GITHUB_WORKFLOW: "yes") do
      expect(provider).to eq(Publisher::Providers::Github)
    end
  end

  it "detects gitlab instance" do
    ClimateControl.modify(GITLAB_CI: "true", GITHUB_WORKFLOW: nil) do
      expect(provider).to eq(Publisher::Providers::Gitlab)
    end
  end
end
