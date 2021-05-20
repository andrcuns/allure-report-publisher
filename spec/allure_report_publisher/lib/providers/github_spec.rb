RSpec.describe Publisher::Providers::Github do
  subject(:provider) { described_class.new(results_path: results_path, report_url: report_url, update_pr: update_pr) }

  let(:results_path) { Dir.mktmpdir("allure-results", "tmp") }
  let(:report_url) { "https://report.com" }
  let(:auth_token) { "token" }
  let(:event_name) { "pull_request" }
  let(:update_pr) { "description" }
  let(:sha) { "e1de5e18c3af8" }
  let(:sha_url) do
    "[#{sha}](#{env[:GITHUB_SERVER_URL]}/#{env[:GITHUB_REPOSITORY]}/pull/1/commits/#{sha})"
  end

  let(:env) do
    {
      GITHUB_WORKFLOW: "yes",
      GITHUB_SERVER_URL: "https://github.com",
      GITHUB_REPOSITORY: "andrcuns/allure-report-publisher",
      GITHUB_JOB: "test",
      GITHUB_RUN_ID: "123",
      GITHUB_API_URL: "https://api.github.com",
      GITHUB_EVENT_PATH: "spec/fixture/workflow_event.json",
      GITHUB_AUTH_TOKEN: auth_token,
      GITHUB_EVENT_NAME: event_name
    }.compact
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end

  context "when adding executor info" do
    it "creates correct executor.json file" do
      provider.write_executor_info

      expect(JSON.parse(File.read("#{results_path}/executor.json"), symbolize_names: true)).to eq(
        {
          name: "Github",
          type: "github",
          reportName: "AllureReport",
          url: env[:GITHUB_SERVER_URL],
          reportUrl: report_url,
          buildUrl: "#{env[:GITHUB_SERVER_URL]}/#{env[:GITHUB_REPOSITORY]}/actions/runs/#{env[:GITHUB_RUN_ID]}",
          buildOrder: env[:GITHUB_RUN_ID],
          buildName: env[:GITHUB_JOB]
        }
      )
    end
  end

  context "with pr context" do
    let(:full_pr_description) { "pr description" }

    let(:octokit) do
      instance_double(
        "Octokit::Client",
        pull_request: { body: full_pr_description },
        update_pull_request: nil,
        add_comment: nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new)
        .with(access_token: env[:GITHUB_AUTH_TOKEN], api_endpoint: env[:GITHUB_API_URL])
        .and_return(octokit)
    end

    context "with add report url to mr description arg for new pr" do
      it "updates pr description" do
        provider.add_report_url

        expect(octokit).to have_received(:update_pull_request).with(
          env[:GITHUB_REPOSITORY],
          1,
          body: <<~DESC.strip
            #{full_pr_description}

            <!-- allure -->
            ---
            # Allure report
            `allure-report-publisher` generated allure report for #{sha_url}!

            **#{env[:GITHUB_JOB]}**: 📝 [allure report](#{report_url})
            <!-- allurestop -->
          DESC
        )
      end
    end

    context "with add report url to mr description arg for existing pr" do
      let(:pr_description) { "pr description" }
      let(:full_pr_description) do
        <<~PR
          #{pr_description}

          <!-- allure -->
            ---
            # Allure report
            `allure-report-publisher` generated allure report for sha_url!

            **#{env[:GITHUB_JOB]}**: 📝 [allure report](report_url)
          <!-- allurestop -->
        PR
      end

      it "updates pr description" do
        provider.add_report_url

        expect(octokit).to have_received(:update_pull_request).with(
          env[:GITHUB_REPOSITORY],
          1,
          body: <<~DESC.strip
            #{pr_description}

            <!-- allure -->
            ---
            # Allure report
            `allure-report-publisher` generated allure report for #{sha_url}!

            **#{env[:GITHUB_JOB]}**: 📝 [allure report](#{report_url})
            <!-- allurestop -->
          DESC
        )
      end
    end

    context "with add report url as comment arg" do
      let(:update_pr) { "comment" }

      it "adds comment" do
        provider.add_report_url

        expect(octokit).to have_received(:add_comment).with(
          env[:GITHUB_REPOSITORY],
          1,
          <<~DESC.strip
            # Allure report
            `allure-report-publisher` generated allure report for #{sha_url}!

            **#{env[:GITHUB_JOB]}**: 📝 [allure report](#{report_url})
          DESC
        )
      end
    end
  end

  context "without pr ci context" do
    let(:event_name) { "push" }

    it "skips adding allure link to pr with not a pr message" do
      expect { provider.add_report_url }.to raise_error("Not a pull request, skipped!")
    end
  end

  context "without configured auth token" do
    let(:auth_token) { nil }

    it "skips adding allure link to pr with not configured auth token message" do
      expect { provider.add_report_url }.to raise_error("Missing GITHUB_AUTH_TOKEN environment variable!")
    end
  end
end
