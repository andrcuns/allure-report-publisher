RSpec.describe Publisher::Providers do
  subject(:provider) { described_class.provider }

  it "detects github instance" do
    ClimateControl.modify(GITHUB_WORKFLOW: "yes") do
      expect(provider).to eq(Publisher::Providers::Github)
    end
  end
end
