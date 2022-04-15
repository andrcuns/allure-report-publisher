RSpec.describe Publisher::Commands::Version, epic: "commands" do
  include_context "with cli helper"

  it "prints version" do
    expect { run_cli("--version") }.to output("#{Publisher::VERSION}\n").to_stdout
  end
end
