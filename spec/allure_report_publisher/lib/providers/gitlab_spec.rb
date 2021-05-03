RSpec.describe Publisher::Providers::Gitlab do
  subject(:provider) { described_class.new(results_path, report_url) }

  let(:results_path) { Dir.mktmpdir("allure-results", "tmp") }
  let(:report_url) { "https://report.com" }
  let(:auth_token) { "token" }
  let(:event_name) { "merge_request_event" }

  let(:env) do
    {
      GITLAB_CI: "yes",
      CI_SERVER_URL: "https://gitlab.com",
      CI_PROJECT_PATH: "andrcuns/allure-report-publisher",
      CI_MERGE_REQUEST_IID: "1",
      CI_JOB_NAME: "test",
      CI_PIPELINE_ID: "123",
      CI_PIPELINE_URL: "https://gitlab.com/pipeline/url",
      CI_PIPELINE_SOURCE: event_name,
      GITLAB_AUTH_TOKEN: auth_token
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
          name: "Gitlab",
          type: "gitlab",
          reportName: "AllureReport",
          url: env[:CI_SERVER_URL],
          reportUrl: report_url,
          buildUrl: env[:CI_PIPELINE_URL],
          buildOrder: env[:CI_PIPELINE_ID],
          buildName: env[:CI_JOB_NAME]
        }
      )
    end
  end

  context "when adding allure report url to mr description" do
    context "with mr context" do
      let(:mr_description) { "mr description" }
      let(:gitlab) do
        instance_double(
          "Gitlab::Client",
          merge_request: double("mr", description: mr_description),
          update_merge_request: nil
        )
      end

      before do
        allow(Gitlab::Client).to receive(:new)
          .with(private_token: env[:GITLAB_AUTH_TOKEN], endpoint: "#{env[:CI_SERVER_URL]}/api/v4")
          .and_return(gitlab)
      end

      it "updates mr description with latest allure report link" do
        provider.add_report_url

        expect(gitlab).to have_received(:update_merge_request).with(
          env[:CI_PROJECT_PATH],
          env[:CI_MERGE_REQUEST_IID],
          description: <<~DESC.strip
            #{mr_description}

            <!-- allure -->
            ---
            📝 [Latest allure report](#{report_url})
            <!-- allurestop -->
          DESC
        )
      end
    end

    context "without mr ci context" do
      let(:event_name) { "push" }

      it "skips adding allure link to mr with not a pr message" do
        expect { provider.add_report_url }.to raise_error("Not a pull request, skipped!")
      end
    end

    context "without configured auth token" do
      let(:auth_token) { nil }

      it "skips adding allure link to pr with not configured auth token message" do
        expect { provider.add_report_url }.to raise_error("Missing GITLAB_AUTH_TOKEN environment variable!")
      end
    end
  end
end
