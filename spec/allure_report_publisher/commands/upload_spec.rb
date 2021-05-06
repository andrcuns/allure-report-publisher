require_relative "./common_uploader_command"

# rubocop:disable RSpec/ContextWording
RSpec.describe Publisher::Commands::Upload do
  context "s3 uploader" do
    let(:uploader) { Publisher::Uploaders::S3 }
    let(:uploader_stub) { instance_double("Publisher::Uploaders::S3", execute: nil) }
    let(:command) { %w[upload s3] }

    it_behaves_like "upload command"
  end

  context "gcs uploader" do
    let(:uploader) { Publisher::Uploaders::GCS }
    let(:uploader_stub) { instance_double("Publisher::Uploaders::GCS", execute: nil) }
    let(:command) { %w[upload gcs] }

    it_behaves_like "upload command"
  end
end
# rubocop:enable RSpec/ContextWording
