require_relative "common_uploader_command"

RSpec.describe Publisher::Commands::Upload, epic: "commands" do
  describe "s3 uploader" do
    let(:command) { %w[upload s3] }

    it_behaves_like "upload command", Publisher::Uploaders::S3
  end

  describe "gcs uploader" do
    let(:command) { %w[upload gcs] }

    it_behaves_like "upload command", Publisher::Uploaders::GCS
  end

  describe "gitlab-artifacts uploader" do
    let(:command) { %w[upload gitlab-artifacts] }

    it_behaves_like "upload command", Publisher::Uploaders::GitlabArtifacts
  end
end
