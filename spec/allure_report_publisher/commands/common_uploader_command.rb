RSpec.shared_examples "upload command" do
  include_context "with cli helper"
  include_context "with output capture"

  let(:result_glob) { "spec/fixture/fake_results" }
  let(:result_paths) { [result_glob] }
  let(:bucket) { "bucket" }
  let(:prefix) { "my-project/prs" }
  let(:report_title) { "Allure Report" }
  let(:uploader_stub) do
    instance_double(
      uploader.to_s,
      generate_report: nil,
      upload: nil,
      report_urls: { "Report url" => "http://report.com" },
      add_result_summary: nil,
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
      result_paths: result_paths,
      bucket: bucket,
      prefix: prefix,
      copy_latest: false,
      summary_type: nil,
      collapse_summary: false,
      unresolved_discussion_on_failure: false,
      summary_table_type: :ascii,
      report_title: report_title
    }
  end

  before do
    allow(uploader).to receive(:new) { uploader_stub }
    allow(Publisher::Helpers).to receive(:allure_cli?)
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
          **args.slice(
            :result_paths,
            :bucket,
            :copy_latest,
            :update_pr,
            :summary_type,
            :summary_table_type,
            :collapse_summary,
            :unresolved_discussion_on_failure,
            :report_title
          )
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
      expect(uploader_stub).to have_received(:add_result_summary)
    end

    it "executes uploader with --report-title=title" do
      run_cli(*command, *cli_args, "--report-title=custom title")

      expect(uploader).to have_received(:new).with({ **args, report_title: "custom title" })
      expect(uploader_stub).to have_received(:generate_report)
      expect(uploader_stub).to have_received(:upload)
    end

    it "executes uploader with --update-pr=description" do
      run_cli(*command, *cli_args, "--update-pr=description")

      aggregate_failures do
        expect(uploader).to have_received(:new).with({ **args, update_pr: "description" })
        expect(uploader_stub).to have_received(:generate_report)
        expect(uploader_stub).to have_received(:upload)
        expect(uploader_stub).to have_received(:add_result_summary)
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
        expect(uploader_stub).to have_received(:add_result_summary)
      end
    end

    it "executes uploader with --summary-table-type=markdown" do
      run_cli(*command, *cli_args, "--update-pr=comment", "--summary=behaviors", "--summary-table-type=markdown")

      aggregate_failures do
        expect(uploader).to have_received(:new).with(
          { **args, update_pr: "comment", summary_type: "behaviors", summary_table_type: :markdown }
        )
        expect(uploader_stub).to have_received(:generate_report)
        expect(uploader_stub).to have_received(:upload)
        expect(uploader_stub).to have_received(:add_result_summary)
      end
    end

    it "executes uploader with custom --base-url" do
      base_url = "https://custom"

      run_cli(*command, *cli_args, "--base-url=#{base_url}")

      aggregate_failures do
        expect(uploader).to have_received(:new).with({ **args, base_url: base_url })
        expect(uploader_stub).to have_received(:generate_report)
        expect(uploader_stub).to have_received(:upload)
      end
    end
  end

  context "with environment variable arguments" do
    around do |example|
      ClimateControl.modify(env) { example.run }
    end

    context "with valid arguments" do
      let(:env) { { ALLURE_UPDATE_PR: "comment" } }

      it "fetches option from environment variable" do
        run_cli(*command, *cli_args)

        expect(uploader).to have_received(:new).with({ **args, update_pr: "comment" })
      end
    end

    context "with boolean type arguments" do
      let(:env) { { ALLURE_COPY_LATEST: "true" } }

      it "correctly casts boolean type argument" do
        run_cli(*command, *cli_args)

        expect(uploader).to have_received(:new).with({ **args, copy_latest: true })
      end
    end

    context "with invalid arguments" do
      let(:env) { { ALLURE_UPDATE_PR: "bla" } }

      it "exits when environment variable contains invalid value" do
        expect { run_cli(*command, *cli_args) }.to raise_error(SystemExit)
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

  context "with invalid base-url" do
    it "fails with invalid url error" do
      expect { run_cli(*command, *cli_args, "--base-url=https://bla bla") }.to raise_error(SystemExit)
      expect(uploader_stub).not_to have_received(:generate_report)
      expect(uploader_stub).not_to have_received(:upload)
    end
  end

  context "with failure in spinner block" do
    before do
      allow(uploader_stub).to receive(:generate_report).and_raise(Publisher::Helpers::Spinner::Failure)
    end

    it "exits without printing error" do
      expect { run_cli(*command, *cli_args) }.to raise_error(SystemExit)
    end
  end
end
