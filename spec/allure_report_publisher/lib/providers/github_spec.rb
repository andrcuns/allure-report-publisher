RSpec.describe Publisher::Providers::Github do
  subject(:provider) { described_class.new(report_url: report_url, update_pr: update_pr) }

  let(:report_url) { "https://report.com" }
  let(:auth_token) { "token" }
  let(:event_name) { "pull_request" }
  let(:update_pr) { "description" }
  let(:sha) { "cfdef23b4b06df32ab1e98ee4091504948daf2a9" }
  let(:sha_url) do
    "[#{sha[0..7]}](#{env[:GITHUB_SERVER_URL]}/#{env[:GITHUB_REPOSITORY]}/pull/1/commits/#{sha})"
  end
  let(:urls) do
    <<~URLS.strip
      <!-- allure -->
      ---
      # Allure report
      `allure-report-publisher` generated allure report for #{sha_url}!

      <!-- jobs -->
      **#{env[:GITHUB_JOB]}**: 📝 [allure report](#{report_url})
      <!-- jobs -->
      <!-- allurestop -->
    URLS
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

  context "with any context" do
    it "returns correct executor info" do
      expect(provider.executor_info).to eq(
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
    let(:comments) { [] }

    let(:octokit) do
      instance_double(
        "Octokit::Client",
        pull_request: { body: full_pr_description },
        issue_comments: comments,
        update_pull_request: nil,
        add_comment: nil,
        update_comment: nil
      )
    end

    before do
      allow(Octokit::Client).to receive(:new)
        .with(access_token: env[:GITHUB_AUTH_TOKEN], api_endpoint: env[:GITHUB_API_URL])
        .and_return(octokit)
    end

    context "with add report url to pr description arg for new pr" do
      it "updates pr description" do
        provider.add_report_url

        expect(octokit).to have_received(:update_pull_request).with(
          env[:GITHUB_REPOSITORY],
          1,
          body: <<~DESC.strip
            #{full_pr_description}

            #{urls}
          DESC
        )
      end
    end

    context "with add report url to pr description arg for existing pr" do
      let(:pr_description) { "pr description" }
      let(:full_pr_description) do
        <<~PR.strip
          #{pr_description}

          <!-- allure -->
          ---
          # Allure report
          `allure-report-publisher` generated allure report for sha_url!

          <!-- jobs -->
          **#{env[:GITHUB_JOB]}**: 📝 [allure report](report_url)
          <!-- jobs -->
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

            #{urls}
          DESC
        )
      end
    end

    context "with add report url as comment arg" do
      let(:update_pr) { "comment" }

      context "with new pr" do
        it "adds new comment" do
          provider.add_report_url

          expect(octokit).to have_received(:add_comment).with(env[:GITHUB_REPOSITORY], 1, urls.gsub("---\n", ""))
        end
      end

      context "with existing pr" do
        let(:comments) do
          [{
            id: 2,
            body: <<~BODY
              <!-- allure -->
              # Allure report
              `allure-report-publisher` generated allure report for sha_url!

              <!-- jobs -->
              **#{env[:GITHUB_JOB]}**: 📝 [allure report](report_url)
              <!-- jobs -->
              <!-- allurestop -->
            BODY
          }]
        end

        it "updates existing comment" do
          provider.add_report_url

          expect(octokit).to have_received(:update_comment).with(env[:GITHUB_REPOSITORY], 2, urls.gsub("---\n", ""))
        end
      end
    end
  end

  context "without pr context" do
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
