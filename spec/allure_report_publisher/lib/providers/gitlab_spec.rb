RSpec.describe Publisher::Providers::Gitlab do
  subject(:provider) { described_class.new(report_url: report_url, update_pr: update_pr) }

  let(:report_url) { "https://report.com" }
  let(:auth_token) { "token" }
  let(:event_name) { "merge_request_event" }
  let(:update_pr) { "description" }
  let(:mr_id) { "1" }
  let(:project) { "andrcuns/allure-report-publisher" }
  let(:comment_double) { double("comments", auto_paginate: [comment].compact) }
  let(:comment) { nil }
  let(:sha) { "cfdef23b4b06df32ab1e98ee4091504948daf2a9" }
  let(:sha_url) do
    "[#{sha[0..7]}](#{env[:CI_SERVER_URL]}/#{project}/-/merge_requests/#{mr_id}/diffs?commit_id=#{sha})"
  end

  let(:env) do
    {
      GITLAB_CI: "yes",
      CI_SERVER_URL: "https://gitlab.com",
      CI_JOB_NAME: "test",
      CI_PIPELINE_ID: "123",
      CI_PIPELINE_URL: "https://gitlab.com/pipeline/url",
      CI_PROJECT_PATH: project,
      CI_MERGE_REQUEST_IID: mr_id,
      CI_PIPELINE_SOURCE: event_name,
      GITLAB_AUTH_TOKEN: auth_token,
      CI_MERGE_REQUEST_SOURCE_BRANCH_SHA: sha
    }.compact
  end

  def urls_section(url_sha: sha_url, job_name: env[:CI_JOB_NAME], url_report: report_url)
    <<~URLS.strip
      <!-- allure -->
      ---
      # Allure report
      `allure-report-publisher` generated allure report for #{url_sha}!

      <!-- jobs -->
      **#{job_name}**: 📝 [allure report](#{url_report})
      <!-- jobs -->
      <!-- allurestop -->
    URLS
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end

  context "with any execution context" do
    it "returns correct executor info" do
      expect(provider.executor_info).to eq(
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

  context "with mr context" do
    let(:full_mr_description) { "mr description" }
    let(:gitlab) do
      instance_double(
        "Gitlab::Client",
        merge_request: double("mr", description: full_mr_description),
        merge_request_comments: comment_double,
        update_merge_request: nil,
        create_merge_request_comment: nil,
        edit_merge_request_note: nil
      )
    end

    before do
      allow(Gitlab::Client).to receive(:new)
        .with(private_token: env[:GITLAB_AUTH_TOKEN], endpoint: "#{env[:CI_SERVER_URL]}/api/v4")
        .and_return(gitlab)
    end

    context "with add report url to mr description arg for new mr" do
      it "updates mr description" do
        provider.add_report_url

        expect(gitlab).to have_received(:update_merge_request).with(
          project,
          mr_id,
          description: "#{full_mr_description}\n\n#{urls_section}"
        )
      end
    end

    context "with add report url to mr description arg for existing mr" do
      let(:mr_description) { "pr description" }
      let(:full_mr_description) { "#{mr_description}\n\n#{urls_section(url_sha: 'sha', url_report: 'report')}" }

      it "updates mr description", :test do
        provider.add_report_url

        expect(gitlab).to have_received(:update_merge_request).with(
          project,
          mr_id,
          description: "#{mr_description}\n\n#{urls_section}"
        )
      end
    end

    context "with add report url as comment arg" do
      let(:update_pr) { "comment" }

      context "with new mr" do
        it "adds comment" do
          provider.add_report_url

          expect(gitlab).to have_received(:create_merge_request_comment).with(
            project,
            mr_id,
            urls_section.gsub("---\n", "")
          )
        end
      end

      context "with existing mr" do
        let(:comment) do
          double("comment", id: 2, body: urls_section(url_sha: "sha", url_report: "report"))
        end

        it "updates comment" do
          provider.add_report_url

          expect(gitlab).to have_received(:edit_merge_request_note).with(
            project,
            mr_id,
            2,
            urls_section.gsub("---\n", "")
          )
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
