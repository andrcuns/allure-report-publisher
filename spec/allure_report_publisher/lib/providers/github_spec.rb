require_relative "common_provider"

RSpec.describe Publisher::Providers::Github do
  include_context "with provider helper"

  let(:build_name) { env[:GITHUB_JOB] }
  let(:server_url) { env[:GITHUB_SERVER_URL] }
  let(:repository) { env[:GITHUB_REPOSITORY] }
  let(:run_id) { env[:GITHUB_RUN_ID] }
  let(:api_url) { env[:GITHUB_API_URL] }
  let(:event_name) { "pull_request" }
  let(:sha_url) { "[#{sha[0..7]}](#{server_url}/#{repository}/pull/1/commits/#{sha})" }

  let(:client) do
    instance_double(
      "Octokit::Client",
      pull_request: { body: full_pr_description },
      issue_comments: comments,
      update_pull_request: nil,
      add_comment: nil,
      update_comment: nil
    )
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

  context "with any context" do
    it "returns correct executor info" do
      expect(provider.executor_info).to eq(
        {
          name: "Github",
          type: "github",
          reportName: "AllureReport",
          url: server_url,
          reportUrl: report_url,
          buildUrl: "#{server_url}/#{repository}/actions/runs/#{run_id}",
          buildOrder: run_id,
          buildName: build_name
        }
      )
    end
  end

  context "with pr context" do
    let(:comments) { [] }

    before do
      allow(Octokit::Client).to receive(:new)
        .with(access_token: auth_token, api_endpoint: api_url)
        .and_return(client)
    end

    context "with adding report urls to pr description" do
      it "updates pr description" do
        provider.add_report_url

        expect(url_builder).to have_received(:updated_pr_description).with(full_pr_description)
        expect(client).to have_received(:update_pull_request).with(repository, 1, body: updated_pr_description)
      end
    end

    context "with adding report urls to pr comment" do
      let(:update_pr) { "comment" }

      context "without existing comment" do
        it "adds new comment" do
          provider.add_report_url

          expect(url_builder).to have_received(:comment_body).with(no_args)
          expect(client).to have_received(:add_comment).with(repository, 1, updated_comment_body)
        end
      end

      context "with existing comment" do
        let(:comments) do
          [{
            id: 2,
            body: "existing comment"
          }]
        end

        before do
          allow(Publisher::Providers::UrlSectionBuilder).to receive(:match?)
            .with(comments.first[:body])
            .and_return(true)
        end

        it "updates existing comment" do
          provider.add_report_url

          expect(url_builder).to have_received(:comment_body).with(comments.first[:body])
          expect(client).to have_received(:update_comment).with(repository, 2, updated_comment_body)
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
