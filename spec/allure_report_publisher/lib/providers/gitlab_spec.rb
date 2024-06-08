require_relative "common_provider"
require_relative "gitlab_env"

RSpec.describe Publisher::Providers::Gitlab, epic: "providers" do
  include_context "with provider helper"
  include_context "with gitlab env"

  let(:build_name) { env[:CI_JOB_NAME] }
  let(:server_url) { env[:CI_SERVER_URL] }
  let(:project) { env[:CI_PROJECT_PATH] }
  let(:api_url) { env[:GITHUB_API_URL] }
  let(:comment) { nil }

  let(:sha_url) do
    "[#{sha[0..7]}](#{server_url}/#{project}/-/merge_requests/#{mr_id}/diffs?commit_id=#{sha})"
  end

  let(:custom_sha_url) do
    "[#{sha[0..7]}](#{server_url}/#{custom_project}/-/merge_requests/#{custom_mr_id}/diffs?commit_id=#{sha})"
  end

  let(:comment_double) { double("comments", auto_paginate: [comment].compact) }

  let(:client) do
    instance_double(
      Gitlab::Client,
      merge_request: double("mr", description: full_pr_description),
      merge_request_comments: comment_double,
      update_merge_request: nil,
      create_merge_request_discussion: nil,
      create_merge_request_discussion_note: nil,
      create_merge_request_comment: nil,
      delete_merge_request_discussion_note: nil,
      edit_merge_request_note: nil
    )
  end

  before do
    allow(Gitlab::Client).to receive(:new)
      .with(private_token: auth_token, endpoint: "#{server_url}/api/v4")
      .and_return(client)
  end

  context "with mr context" do
    context "with adding report urls to mr description" do
      it "updates mr description" do
        provider.add_result_summary

        expect(url_builder).to have_received(:updated_pr_description).with(full_pr_description)
        expect(client).to have_received(:update_merge_request).with(project, mr_id, description: updated_pr_description)
      end
    end

    context "with adding report urls to mr comment" do
      let(:update_pr) { "comment" }

      context "without existing comment" do
        it "adds new comment" do
          provider.add_result_summary

          expect(url_builder).to have_received(:comment_body).with(no_args)
          expect(client).to have_received(:create_merge_request_comment).with(project, mr_id, updated_comment_body)
        end
      end

      context "with existing comment" do
        let(:comment_id) { 2 }
        let(:comment) { double("note", id: comment_id, body: "existing comment") }

        before do
          allow(Publisher::Helpers::UrlSectionBuilder).to receive(:match?)
            .with(comment.body)
            .and_return(true)
        end

        it "updates existing comment" do
          provider.add_result_summary

          expect(url_builder).to have_received(:comment_body)
            .with(comment.body)
          expect(client).to have_received(:edit_merge_request_note)
            .with(project, mr_id, comment_id, updated_comment_body)
        end
      end
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
