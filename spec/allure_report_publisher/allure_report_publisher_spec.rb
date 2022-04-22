RSpec.describe Publisher, epic: "cli" do
  it "prints global usage" do
    usage = <<~USE
      Commands:
        allure-report-publisher upload TYPE                   # Generate and upload allure report
        allure-report-publisher version                       # Print version
    USE

    expect { system("bin/allure-report-publisher") }.to(
      output(/#{usage}/).to_stderr_from_any_process
    )
  end
end
