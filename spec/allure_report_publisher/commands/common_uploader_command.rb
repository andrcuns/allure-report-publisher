RSpec.shared_examples "upload command" do
  include_context "with cli helper"
  include_context "with output capture"

  let(:result_glob) { "spec/fixture/fake_results" }
  let(:result_paths) { [result_glob] }
  let(:bucket) { "bucket" }
  let(:prefix) { "my-project/prs" }
  let(:report_title) { "Allure Report" }
  let(:report_url) { "http://report.com" }
  let(:report_path) { "path/to/report" }

  let(:uploader_stub) do
    instance_double(
      uploader.to_s,
      generate_report: nil,
      upload: nil,
      report_urls: { "Report url" => report_url },
      report_url: report_url,
      report_path: report_path
    )
  end

  let(:provider) { Publisher::Providers::Github }
  let(:provider_stub) { instance_double(provider, add_result_summary: nil) }

  let(:cli_args) do
    [
      "--results-glob=#{result_glob}",
      "--bucket=#{bucket}",
      "--prefix=#{prefix}"
    ]
  end

  let(:uploader_args) do
    {
      result_paths: result_paths,
      bucket: bucket,
      prefix: prefix,
      copy_latest: false,
      parallel: 8
    }
  end

  let(:provider_args) do
    {
      report_url: report_url,
      report_path: report_path,
      summary_type: Publisher::Helpers::Summary::TOTAL,
      summary_table_type: Publisher::Helpers::Summary::ASCII,
      collapse_summary: false,
      flaky_warning_status: false,
      report_title: report_title
    }
  end

  before do
    allow(Publisher::Helpers).to receive(:allure_cli?)
    allow(Publisher::Providers).to receive(:provider) { provider }
    allow(Publisher::Providers).to receive_message_chain(:info, :pr?) { true } # rubocop:disable RSpec/MessageChain

    allow(uploader).to receive(:new) { uploader_stub }
    allow(provider).to receive(:new) { provider_stub }
  end

  shared_examples "command" do |additional_cli_args, expected_uploader_args, expected_provider_args|
    it "with #{additional_cli_args.empty? ? 'default' : additional_cli_args.join(' ')} args", :aggregate_failures do
      run_cli(*command, *cli_args, *additional_cli_args)

      expect(uploader).to have_received(:new).with(uploader_args.merge(expected_uploader_args))
      expect(uploader_stub).to have_received(:generate_report)
      expect(uploader_stub).to have_received(:upload)

      if additional_cli_args.any? { |arg| arg.start_with?("--update-pr") }
        expect(provider).to have_received(:new).with(provider_args.merge(expected_provider_args))
        expect(provider_stub).to have_received(:add_result_summary)
      else
        expect(provider).not_to have_received(:new)
      end
    end
  end

  context "with arguments via cli" do
    it_behaves_like "command", [], {}, {}
    it_behaves_like "command", ["--update-pr=comment"],
                    {},
                    { update_pr: "comment" }
    it_behaves_like "command", ["--update-pr=description"],
                    {},
                    { update_pr: "description" }
    it_behaves_like "command", ["--report-title=custom title", "--update-pr=comment"],
                    {},
                    { report_title: "custom title", update_pr: "comment" }
    it_behaves_like "command", ["--copy-latest"],
                    { copy_latest: true },
                    {}
    it_behaves_like "command", ["--update-pr=comment", "--summary=behaviors"],
                    {},
                    { update_pr: "comment", summary_type: "behaviors" }
    it_behaves_like "command", ["--update-pr=comment", "--summary=behaviors", "--summary-table-type=markdown"],
                    {},
                    {
                      update_pr: "comment",
                      summary_type: "behaviors",
                      summary_table_type: Publisher::Helpers::Summary::MARKDOWN
                    }
    it_behaves_like "command", ["--base-url=https://my-url.com"],
                    { base_url: "https://my-url.com" },
                    {}
  end

  context "with arguments via environment variables" do
    around do |example|
      ClimateControl.modify(env) { example.run }
    end

    context "with valid arguments" do
      let(:env) { { ALLURE_UPDATE_PR: "comment" } }

      it "fetches option from environment variable" do
        run_cli(*command, *cli_args)

        expect(provider).to have_received(:new).with(provider_args.merge(update_pr: "comment"))
      end
    end

    context "with boolean type arguments" do
      let(:env) { { ALLURE_COPY_LATEST: "true" } }

      it "correctly casts boolean type argument" do
        run_cli(*command, *cli_args)

        expect(uploader).to have_received(:new).with(uploader_args.merge(copy_latest: true))
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

  context "with invalid parallel option" do
    it "fails with invalid parallel option error" do
      expect { run_cli(*command, *cli_args, "--parallel=0") }.to raise_error(SystemExit)
      expect(uploader_stub).not_to have_received(:generate_report)
      expect(uploader_stub).not_to have_received(:upload)
    end
  end

  context "with variadic arguments" do
    it "passes extra arguments to uploader" do
      run_cli(*command, *cli_args, "--", "--lang", "en")

      expect(uploader_stub).to have_received(:generate_report).with(["--lang", "en"])
    end
  end
end
