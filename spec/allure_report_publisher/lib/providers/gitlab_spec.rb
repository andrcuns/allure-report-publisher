require_relative "common_provider"

RSpec.describe Publisher::Providers::Gitlab, epic: "providers" do
  include_context "with provider helper"

  let(:build_name) { env[:CI_JOB_NAME] }
  let(:server_url) { env[:CI_SERVER_URL] }
  let(:project) { env[:CI_PROJECT_PATH] }
  let(:custom_project) { nil }
  let(:run_id) { env[:CI_PIPELINE_ID] }
  let(:api_url) { env[:GITHUB_API_URL] }
  let(:mr_id) { "1" }
  let(:custom_mr_id) { nil }
  let(:event_name) { "merge_request_event" }
  let(:discussion) { nil }

  let(:sha_url) do
    "[#{sha[0..7]}](#{server_url}/#{project}/-/merge_requests/#{mr_id}/diffs?commit_id=#{sha})"
  end

  let(:custom_sha_url) do
    "[#{sha[0..7]}](#{server_url}/#{custom_project}/-/merge_requests/#{custom_mr_id}/diffs?commit_id=#{sha})"
  end

  let(:comment_double) { double("comments", auto_paginate: [discussion].compact) }

  let(:client) do
    instance_double(
      Gitlab::Client,
      merge_request: double("mr", description: full_pr_description),
      merge_request_discussions: comment_double,
      update_merge_request: nil,
      create_merge_request_discussion: nil,
      create_merge_request_discussion_note: nil,
      create_merge_request_comment: nil,
      delete_merge_request_discussion_note: nil,
      edit_merge_request_note: nil
    )
  end

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
      CI_MERGE_REQUEST_SOURCE_BRANCH_SHA: "",
      CI_COMMIT_SHA: sha,
      GITLAB_AUTH_TOKEN: auth_token,
      ALLURE_PROJECT_PATH: custom_project,
      ALLURE_MERGE_REQUEST_IID: custom_mr_id
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
        provider.add_result_summary

        expect(url_builder).to have_received(:updated_pr_description)
          .with(full_pr_description)
        expect(client).to have_received(:update_merge_request)
          .with(project, mr_id, description: updated_pr_description)
      end
    end

    context "with adding report urls to pr comment" do
      let(:update_pr) { "comment" }

      context "without existing comment" do
        it "adds new comment" do
          provider.add_result_summary

          expect(url_builder).to have_received(:comment_body).with(no_args)
          expect(client).to have_received(:create_merge_request_comment).with(project, mr_id, updated_comment_body)
        end
      end

      context "when there are test failures in summary" do
        before do
          allow(Publisher::Helpers::UrlSectionBuilder).to receive(:match?)
            .with(discussion.body)
            .and_return(true)
          allow(url_builder).to receive(:summary_has_failures?)
            .and_return(true)
        end

        let(:unresolved_discussion_on_failure) { true }
        let(:alert_comment_text) { "There are some test failures that need attention" }
        let(:comment_id) { 2 }
        let(:note_id) { "abc" }
        let(:note) do
          double("note", id: note_id, body: "existing comment")
        end

        let(:discussion) do
          double("comment", id: comment_id, body: "existing comment", notes: [note])
        end

        it "adds a resolvable attention comment" do
          provider.add_result_summary

          expect(client).to have_received(:create_merge_request_discussion_note)
            .with(project, mr_id, comment_id, body: alert_comment_text)
        end
      end

      context "with existing alert comment" do
        let(:comment_id) { 2 }
        let(:note_id) { "abc" }
        let(:note) do
          double("note", id: note_id, body: "existing comment")
        end

        let(:discussion) do
          double("comment", id: comment_id, body: "existing comment", notes: [note])
        end

        let(:alert_comment_text) { "There are some test failures that need attention" }

        let(:existing_alert_note) do
          double("alert note", id: note_id, body: alert_comment_text)
        end

        before do
          allow(Publisher::Helpers::UrlSectionBuilder).to receive(:match?)
            .with(discussion.body)
            .and_return(true)

          allow(provider).to receive(:alert_comment).and_return(existing_alert_note)
        end

        it "removes the alert comment" do
          provider.add_result_summary

          expect(client).to have_received(:delete_merge_request_discussion_note)
            .with(project, mr_id, comment_id, note_id)
        end
      end

      context "with existing comment" do
        let(:comment_id) { 2 }
        let(:note_id) { "abc" }
        let(:note) do
          double("note", id: note_id, body: "existing comment")
        end

        let(:discussion) do
          double("comment", id: comment_id, body: "existing comment", notes: [note])
        end

        before do
          allow(Publisher::Helpers::UrlSectionBuilder).to receive(:match?)
            .with(discussion.body)
            .and_return(true)
        end

        it "updates existing comment" do
          provider.add_result_summary

          expect(url_builder).to have_received(:comment_body)
            .with(discussion.body)
          expect(client).to have_received(:edit_merge_request_note)
            .with(project, mr_id, note_id, updated_comment_body)
        end
      end
    end
  end

  context "without mr ci context" do
    let(:event_name) { "push" }

    it "skips adding allure link to mr with not a pr message" do
      expect { provider.add_result_summary }.to raise_error("Not a pull request, skipped!")
    end
  end

  context "without configured auth token" do
    let(:auth_token) { nil }

    it "skips adding allure link to pr with not configured auth token message" do
      expect { provider.add_result_summary }.to raise_error("Missing GITLAB_AUTH_TOKEN environment variable!")
    end
  end

  context "with overridden parameters" do
    let(:event_name) { "push" }
    let(:custom_project) { "custom/project" }
    let(:custom_mr_id) { "123" }
    let(:sha_url) { custom_sha_url }

    it "updates mr description with custom parameters for non mr runs" do
      provider.add_result_summary

      expect(url_builder).to have_received(:updated_pr_description)
        .with(full_pr_description)
      expect(client).to have_received(:update_merge_request)
        .with(custom_project, custom_mr_id, description: updated_pr_description)
    end
  end
end
