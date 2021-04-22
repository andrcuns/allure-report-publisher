RSpec.describe Allure::Publisher do
  it "prints global usage" do
    usage = <<~USE
      Commands:
        allure-report-publisher upload [SUBCOMMAND]
        allure-report-publisher version                                   # Print version
    USE

    expect { system("bin/allure-report-publisher") }.to(
      output(usage).to_stderr_from_any_process
    )
  end

  it "prints upload usage" do
    usage = <<~USE
      Commands:
        allure-report-publisher upload s3                  # Generate and upload allure report
    USE

    expect { system("bin/allure-report-publisher upload --help") }.to(
      output(usage).to_stderr_from_any_process
    )
  end
end
