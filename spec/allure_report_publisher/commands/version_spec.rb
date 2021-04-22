RSpec.describe Allure::Publisher::Commands::Version do
  it "prints version" do
    expect { Dry::CLI.new(Allure::Publisher::Commands).call(arguments: ["--version"]) }.to(
      output("#{Allure::Publisher::VERSION}\n").to_stdout
    )
  end
end
