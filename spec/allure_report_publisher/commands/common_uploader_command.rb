RSpec.shared_examples "upload command" do
  include_context "with cli helper"
  include_context "with output capture"

  let(:result_glob) { "**/*" }
  let(:bucket) { "bucket" }
  let(:prefix) { "my-project/prs" }
  let(:uploader_stub) do
    instance_double(
      uploader.to_s,
      generate_report: nil,
      upload: nil,
      report_urls: { "Report url" => "http://report.com" },
      add_url_to_pr: nil,
      pr?: true
    )
  end

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
      copy_latest: false,
      summary_type: nil
    }
  end

  before do
    allow(uploader).to receive(:new) { uploader_stub }
    allow(Publisher::Helpers).to receive(:validate_allure_cli_present)
  end

  context "with required args", :aggregate_failures do
    it "executes uploader" do
      run_cli(*command, *cli_args)

      expect(uploader).to have_received(:new).with(args)
      expect(uploader_stub).to have_received(:generate_report)
      expect(uploader_stub).to have_received(:upload)
    end

    it "executes uploader without prefix argument" do
      run_cli(*command, *cli_args[0, 2])

      aggregate_failures do
        expect(uploader).to have_received(:new).with(
          args.slice(:results_glob, :bucket, :copy_latest, :update_pr, :summary_type)
        )
        expect(uploader_stub).to have_received(:generate_report)
        expect(uploader_stub).to have_received(:upload)
      end
    end
  end

  context "with optional args", :aggregate_failures do
    it "executes uploader with --update-pr=comment" do
      run_cli(*command, *cli_args, "--update-pr=comment")

      expect(uploader).to have_received(:new).with({ **args, update_pr: "comment" })
      expect(uploader_stub).to have_received(:generate_report)
      expect(uploader_stub).to have_received(:upload)
      expect(uploader_stub).to have_received(:add_url_to_pr)
    end

    it "executes uploader with --update-pr=description" do
      run_cli(*command, *cli_args, "--update-pr=description")

      aggregate_failures do
        expect(uploader).to have_received(:new).with({ **args, update_pr: "description" })
        expect(uploader_stub).to have_received(:generate_report)
        expect(uploader_stub).to have_received(:upload)
        expect(uploader_stub).to have_received(:add_url_to_pr)
      end
    end

    it "executes uploader with --copy-latest" do
      run_cli(*command, *cli_args, "--copy-latest")

      aggregate_failures do
        expect(uploader).to have_received(:new).with({ **args, copy_latest: true })
        expect(uploader_stub).to have_received(:generate_report)
        expect(uploader_stub).to have_received(:upload)
      end
    end

    it "executes uploader with --summary=behaviors" do
      run_cli(*command, *cli_args, "--update-pr=comment", "--summary=behaviors")

      aggregate_failures do
        expect(uploader).to have_received(:new).with({ **args, update_pr: "comment", summary_type: "behaviors" })
        expect(uploader_stub).to have_received(:generate_report)
        expect(uploader_stub).to have_received(:upload)
        expect(uploader_stub).to have_received(:add_url_to_pr)
      end
    end
  end

  context "with missing args", :aggregate_failures do
    it "exits when result glob is missing" do
      expect { run_cli(*command, cli_args[1]) }.to raise_error(SystemExit)
      expect(uploader_stub).not_to have_received(:generate_report)
      expect(uploader_stub).not_to have_received(:upload)
    end

    it "exits when bucket is missing" do
      expect { run_cli(*command, cli_args[0]) }.to raise_error(SystemExit)
      expect(uploader_stub).not_to have_received(:generate_report)
      expect(uploader_stub).not_to have_received(:upload)
    end
  end
end
