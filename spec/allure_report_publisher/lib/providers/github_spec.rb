require_relative "common_provider"
require_relative "github_env"

RSpec.describe Publisher::Providers::Github, epic: "providers" do
  include_context "with provider helper"
  include_context "with github env"

  let(:build_name) { env[:GITHUB_JOB] }
  let(:server_url) { env[:GITHUB_SERVER_URL] }
  let(:repository) { env[:GITHUB_REPOSITORY] }
  let(:run_id) { env[:GITHUB_RUN_ID] }
  let(:api_url) { env[:GITHUB_API_URL] }
  let(:sha_url) { "[#{sha[0..7]}](#{server_url}/#{repository}/pull/1/commits/#{sha})" }

  let(:client) do
    instance_double(
      Octokit::Client,
      pull_request: { body: full_pr_description },
      issue_comments: comments,
      update_pull_request: nil,
      add_comment: nil,
      update_comment: nil
    )
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
        provider.add_result_summary

        expect(url_builder).to have_received(:updated_pr_description).with(full_pr_description)
        expect(client).to have_received(:update_pull_request).with(repository, 1, body: updated_pr_description)
      end
    end

    context "with adding report urls to pr comment" do
      let(:update_pr) { "comment" }

      context "without existing comment" do
        it "adds new comment" do
          provider.add_result_summary

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
          allow(Publisher::Helpers::UrlSectionBuilder).to receive(:match?)
            .with(comments.first[:body])
            .and_return(true)
        end

        it "updates existing comment" do
          provider.add_result_summary

          expect(url_builder).to have_received(:comment_body).with(comments.first[:body])
          expect(client).to have_received(:update_comment).with(repository, 2, updated_comment_body)
        end
      end
    end

    context "with adding report urls to step summary" do
      let(:update_pr) { "actions" }
      let(:step_summary_file) { Tempfile.create("summary", "tmp").path }

      after do
        File.unlink(step_summary_file)
      end

      it "writes to step summary file" do
        provider.add_result_summary

        expect(url_builder).to have_received(:comment_body).with(no_args)
        expect(File.read(step_summary_file)).to eq(updated_comment_body)
      end
    end
  end

  context "without configured auth token" do
    let(:auth_token) { nil }

    it "skips adding allure link to pr with not configured auth token message" do
      expect { provider.add_result_summary }.to raise_error("Missing GITHUB_AUTH_TOKEN environment variable!")
    end
  end
end
