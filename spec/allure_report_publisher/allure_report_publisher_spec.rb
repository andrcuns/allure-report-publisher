RSpec.describe Allure::Publisher do
  it "prints usage" do
    out = StringIO.new

    aggregate_failures do
      expect { Dry::CLI.new(Allure::Publisher::Commands).call(out: out, err: out) }.to raise_error(SystemExit)
      expect(out.string).to eq(<<~MSG)
        Commands:
          rspec upload         # Generate and upload allure report
          rspec version        # Print version
      MSG
    end
  end
end
