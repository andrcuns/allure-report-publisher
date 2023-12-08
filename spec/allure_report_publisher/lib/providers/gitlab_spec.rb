require_relative "common_provider"
require_relative "gitlab_env"

RSpec.describe Publisher::Providers::Gitlab, epic: "providers" do
  include_context "with provider helper"
  include_context "with gitlab env"

  let(:build_name) { env[:CI_JOB_NAME] }
  let(:server_url) { env[:CI_SERVER_URL] }
  let(:project) { env[:CI_PROJECT_PATH] }
  let(:run_id) { env[:CI_PIPELINE_ID] }
  let(:api_url) { env[:GITHUB_API_URL] }
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
        let(:note_id) { "abc" }
        let(:note) { double("note", id: note_id, body: "existing comment") }
        let(:discussion) { double("comment", id: comment_id, body: "existing comment", notes: [note]) }

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

      # rubocop:disable RSpec/NestedGroups
      context "with resolvable comment" do
        let(:unresolved_discussion_on_failure) { true }
        let(:main_comment_body) { "Allure report body" }
        let(:alert_comment_text) { "There are some test failures that need attention" }
        let(:discussion_id) { 2 }
        let(:alert_note_id) { "def" }
        let(:notes) { [main_comment] }

        let(:discussion) { double("comment", id: discussion_id, notes: notes) }
        let(:main_comment) { double("main comment", id: "abc", body: main_comment_body) }
        let(:existing_alert_note) { double("alert note", id: alert_note_id, body: alert_comment_text) }

        before do
          allow(Publisher::Helpers::UrlSectionBuilder).to receive(:match?)
            .with(any_args)
            .and_return(true)
        end

        context "when there are no test failures in summary" do
          it "does not add a resolvable attention comment" do
            provider.add_result_summary

            expect(client).not_to have_received(:create_merge_request_discussion_note)
          end
        end

        context "when there are test failures in summary" do
          let(:main_comment_body) { "Allure report body with ❌" }

          it "adds a resolvable attention comment" do
            provider.add_result_summary

            expect(client).to have_received(:create_merge_request_discussion_note)
              .with(project, mr_id, discussion_id, body: alert_comment_text)
          end
        end

        context "when alert comment exists and no ❌ in main comment" do
          let(:notes) { [main_comment, existing_alert_note] }

          before do
            allow(provider).to receive(:alert_comment).and_return(existing_alert_note)
          end

          it "removes the alert comment" do
            provider.add_result_summary

            expect(client).to have_received(:delete_merge_request_discussion_note)
              .with(project, mr_id, discussion_id, alert_note_id)
          end
        end

        context "when alert comment exists and ❌ in main comment" do
          let(:notes) { [main_comment, existing_alert_note] }
          let(:main_comment_body) { "Allure report body with ❌" }

          before do
            allow(provider).to receive(:alert_comment).and_return(existing_alert_note)
          end

          it "does not remove the alert comment" do
            provider.add_result_summary

            expect(client).not_to have_received(:delete_merge_request_discussion_note)
          end
        end
      end
      # rubocop:enable RSpec/NestedGroups
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
