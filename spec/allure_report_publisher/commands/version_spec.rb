RSpec.describe Allure::Publisher::Commands::Version do
  include_context "with cli helper"

  it "prints version" do
    expect { run_cli("--version") }.to output("#{Allure::Publisher::VERSION}\n").to_stdout
  end
end
