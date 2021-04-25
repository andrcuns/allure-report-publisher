RSpec.describe Publisher::Commands::UploadS3 do
  include_context "with cli helper"

  let(:s3_uploader) { instance_double("Publisher::Uploaders::S3", execute: nil) }
  let(:result_glob) { "**/*" }
  let(:bucket) { "bucket" }
  let(:prefix) { "my-project/prs" }
  let(:command) { %w[upload s3] }
  let(:args) { ["--result-files-glob=#{result_glob}", "--bucket=#{bucket}", "--prefix=#{prefix}"] }

  before do
    allow(Publisher::Uploaders::S3).to receive(:new) { s3_uploader }
  end

  context "with required args" do
    it "executes s3 uploader" do
      run_cli(*command, *args)

      aggregate_failures do
        expect(Publisher::Uploaders::S3).to have_received(:new).with(result_glob, bucket, prefix)
        expect(s3_uploader).to have_received(:execute)
      end
    end

    it "executes s3 uploader without prefix argument" do
      run_cli(*command, *args[0, 2])

      aggregate_failures do
        expect(Publisher::Uploaders::S3).to have_received(:new).with(result_glob, bucket, nil)
        expect(s3_uploader).to have_received(:execute)
      end
    end
  end

  context "with missing args" do
    it "exits when result glob is missing" do
      expect { expect { run_cli(*command, args[1]) }.to raise_error(SystemExit) }.to output.to_stdout
      expect(s3_uploader).not_to have_received(:execute)
    end

    it "exits when bucket is missing" do
      expect { expect { run_cli(*command, args[0]) }.to raise_error(SystemExit) }.to output.to_stdout
      expect(s3_uploader).not_to have_received(:execute)
    end
  end
end
