require_relative "common_provider"

RSpec.describe Publisher::Providers::Gitlab do
  include_context "with provider helper"

  let(:build_name) { env[:CI_JOB_NAME] }
  let(:server_url) { env[:CI_SERVER_URL] }
  let(:repository) { env[:CI_PROJECT_PATH] }
  let(:run_id) { env[:CI_PIPELINE_ID] }
  let(:api_url) { env[:GITHUB_API_URL] }
  let(:mr_id) { "1" }
  let(:event_name) { "merge_request_event" }
  let(:sha_url) { "[#{sha[0..7]}](#{server_url}/#{repository}/-/merge_requests/1/diffs?commit_id=#{sha})" }

  let(:client) do
    instance_double(
      "Gitlab::Client",
      merge_request: double("mr", description: full_pr_description),
      merge_request_comments: comment_double,
      update_merge_request: nil,
      create_merge_request_comment: nil,
      edit_merge_request_note: nil
    )
  end
  let(:comment_double) { double("comments", auto_paginate: [comment].compact) }
  let(:comment) { nil }

  let(:env) do
    {
      GITLAB_CI: "yes",
      CI_SERVER_URL: "https://gitlab.com",
      CI_JOB_NAME: "test",
      CI_PIPELINE_ID: "123",
      CI_PIPELINE_URL: "https://gitlab.com/pipeline/url",
      CI_PROJECT_PATH: "project",
      CI_MERGE_REQUEST_IID: mr_id,
      CI_PIPELINE_SOURCE: event_name,
      GITLAB_AUTH_TOKEN: auth_token,
      CI_MERGE_REQUEST_SOURCE_BRANCH_SHA: sha
    }.compact
  end

  before do
    allow(Gitlab::Client).to receive(:new)
      .with(private_token: auth_token, endpoint: "#{server_url}/api/v4")
      .and_return(client)
  end

  context "with any execution context" do
    it "returns correct executor info" do
      expect(provider.executor_info).to eq(
        {
          name: "Gitlab",
          type: "gitlab",
          reportName: "AllureReport",
          url: server_url,
          reportUrl: report_url,
          buildUrl: env[:CI_PIPELINE_URL],
          buildOrder: run_id,
          buildName: build_name
        }
      )
    end
  end

  context "with pr context" do
    context "with adding report urls to pr description" do
      it "updates pr description" do
        provider.add_report_url

        expect(url_builder).to have_received(:updated_pr_description)
          .with(full_pr_description)
        expect(client).to have_received(:update_merge_request)
          .with(repository, mr_id, description: updated_pr_description)
      end
    end

    context "with adding report urls to pr comment" do
      let(:update_pr) { "comment" }

      context "without existing comment" do
        it "adds new comment" do
          provider.add_report_url

          expect(url_builder).to have_received(:comment_body).with(no_args)
          expect(client).to have_received(:create_merge_request_comment).with(repository, mr_id, updated_comment_body)
        end
      end

      context "with existing comment" do
        let(:comment_id) { 2 }
        let(:comment) do
          double("comment", id: comment_id, body: "existing comment")
        end

        before do
          allow(Publisher::Providers::UrlSectionBuilder).to receive(:match?)
            .with(comment.body)
            .and_return(true)
        end

        it "updates existing comment" do
          provider.add_report_url

          expect(url_builder).to have_received(:comment_body)
            .with(comment.body)
          expect(client).to have_received(:edit_merge_request_note)
            .with(repository, mr_id, comment_id, updated_comment_body)
        end
      end
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
