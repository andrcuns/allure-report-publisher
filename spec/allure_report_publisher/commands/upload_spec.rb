require_relative "common_uploader_command"

RSpec.describe Publisher::Commands::Upload, epic: "commands" do
  describe "s3 uploader" do
    let(:uploader) { Publisher::Uploaders::S3 }
    let(:command) { %w[upload s3] }

    it_behaves_like "upload command"
  end

  describe "gcs uploader" do
    let(:uploader) { Publisher::Uploaders::GCS }
    let(:uploader_stub) { instance_double(Publisher::Uploaders::GCS, execute: nil) }
    let(:command) { %w[upload gcs] }

    it_behaves_like "upload command"
  end
end
