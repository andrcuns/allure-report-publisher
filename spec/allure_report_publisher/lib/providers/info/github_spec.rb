RSpec.describe Publisher::Providers::Info::Github do
  subject(:pr) { described_class.instance.pr? }

  let(:event_name) { "push" }
  let(:env) { { GITHUB_EVENT_NAME: event_name } }

  around do |example|
    ClimateControl.modify(env) { example.run }
  end

  describe "#pr?" do
    context "with non pr event" do
      it { is_expected.to be(false) }
    end

    context "with pr event" do
      let(:event_name) { "pull_request" }

      it { is_expected.to be(true) }
    end
  end
end
