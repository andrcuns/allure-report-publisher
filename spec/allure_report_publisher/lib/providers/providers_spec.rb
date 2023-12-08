RSpec.describe Publisher::Providers, epic: "providers" do
  context "with github workflow" do
    around do |example|
      ClimateControl.modify(GITHUB_WORKFLOW: "yes") do
        example.run
      end
    end

    it "returns github provider instance" do
      expect(described_class.provider).to eq(Publisher::Providers::Github)
    end

    it "returns github info instance" do
      expect(described_class.info).to be_a Publisher::Providers::Info::Github
    end
  end

  context "with gitlab ci" do
    around do |example|
      ClimateControl.modify(GITLAB_CI: "true", GITHUB_WORKFLOW: nil) do
        example.run
      end
    end

    it "returns gitlab provider instance" do
      expect(described_class.provider).to eq(Publisher::Providers::Gitlab)
    end

    it "returns gitlab info instance" do
      expect(described_class.info).to be_a Publisher::Providers::Info::Gitlab
    end
  end
end
