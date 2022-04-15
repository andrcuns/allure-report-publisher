RSpec.shared_context("with provider helper") do
  subject(:provider) do
    described_class.new(
      report_url: report_url,
      report_path: report_path,
      update_pr: update_pr,
      summary_type: summary_type
    )
  end

  let(:url_builder) do
    instance_double(
      "Publesher::Providers:UrlSectionBuilder",
      updated_pr_description: updated_pr_description,
      comment_body: updated_comment_body
    )
  end

  let(:report_url) { "https://report.com" }
  let(:report_path) { "report_path" }
  let(:auth_token) { "token" }
  let(:full_pr_description) { "pr description" }
  let(:updated_pr_description) { "updated description" }
  let(:updated_comment_body) { "updated comment" }
  let(:update_pr) { "description" }
  let(:sha) { "cfdef23b4b06df32ab1e98ee4091504948daf2a9" }
  let(:summary_type) { nil }

  before do
    allow(Publisher::Providers::UrlSectionBuilder).to receive(:new)
      .with(
        report_url: report_url,
        report_path: report_path,
        build_name: build_name,
        sha_url: sha_url,
        summary_type: summary_type
      )
      .and_return(url_builder)
  end

  around do |example|
    ClimateControl.modify(env) { example.run }
  end
end
