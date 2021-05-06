RSpec.shared_examples("upload command") do
  include_context "with cli helper"

  let(:result_glob) { "**/*" }
  let(:bucket) { "bucket" }
  let(:prefix) { "my-project/prs" }
  let(:cli_args) do
    [
      "--results-glob=#{result_glob}",
      "--bucket=#{bucket}",
      "--prefix=#{prefix}"
    ]
  end
  let(:args) do
    {
      results_glob: result_glob,
      bucket: bucket,
      prefix: prefix,
      update_pr: false,
      copy_latest: false
    }
  end

  before do
    allow(uploader).to receive(:new) { uploader_stub }
    allow(Publisher::Helpers).to receive(:validate_allure_cli_present)
  end

  context "with required args" do
    it "executes uploader" do
      run_cli(*command, *cli_args)

      aggregate_failures do
        expect(uploader).to have_received(:new).with(args)
        expect(uploader_stub).to have_received(:execute)
      end
    end

    it "executes uploader without prefix argument" do
      run_cli(*command, *cli_args[0, 2])

      aggregate_failures do
        expect(uploader).to have_received(:new).with(
          args.slice(:results_glob, :bucket, :copy_latest, :update_pr)
        )
        expect(uploader_stub).to have_received(:execute)
      end
    end
  end

  context "with optional args" do
    it "executes s3 uploader with pr update" do
      run_cli(*command, *cli_args, "--update-pr")

      aggregate_failures do
        expect(uploader).to have_received(:new).with({ **args, update_pr: true })
        expect(uploader_stub).to have_received(:execute)
      end
    end

    it "executes s3 uploader with copy latest" do
      run_cli(*command, *cli_args, "--copy-latest")

      aggregate_failures do
        expect(uploader).to have_received(:new).with({ **args, copy_latest: true })
        expect(uploader_stub).to have_received(:execute)
      end
    end
  end

  context "with missing args" do
    it "exits when result glob is missing" do
      expect { expect { run_cli(*command, cli_args[1]) }.to raise_error(SystemExit) }.to output.to_stderr
      expect(uploader_stub).not_to have_received(:execute)
    end

    it "exits when bucket is missing" do
      expect { expect { run_cli(*command, cli_args[0]) }.to raise_error(SystemExit) }.to output.to_stderr
      expect(uploader_stub).not_to have_received(:execute)
    end
  end
end
