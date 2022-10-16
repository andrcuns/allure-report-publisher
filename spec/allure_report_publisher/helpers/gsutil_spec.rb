RSpec.shared_examples "successfull gsutil upload" do
  it "performs copy command" do
    gsutil.batch_copy(
      source_dir: report_path,
      destination_dir: destination_dir,
      bucket: bucket_name,
      cache_control: cache_control
    )

    expect(Open3).to have_received(:capture3).with([
      "gsutil -o 'Credentials:gs_service_key_file=#{credentials_file}' -m",
      "-h 'Cache-Control:private, max-age=#{cache_control}'",
      "cp -r #{report_path} gs://#{bucket_name}/#{destination_dir}"
    ].join(" "))
  end

  it "initializes successfully" do
    expect(gsutil.valid?).to be(true)
  end
end

RSpec.shared_examples "unsuccessful initialization" do
  it "initializes unsuccessfully" do
    expect(gsutil.valid?).to be(false)
  end
end

RSpec.describe Publisher::Helpers::Gsutil, epic: "helpers" do
  subject(:gsutil) { described_class.init }

  let(:status) { instance_double(Process::Status, success?: command_status) }
  let(:command_status) { true }
  let(:credentials) { "spec/fixture/keyfile.json" }
  let(:credentials_file) { credentials }
  let(:report_path) { "report_path" }
  let(:destination_dir) { "destination_dir" }
  let(:bucket_name) { "bucket" }
  let(:cache_control) { 60 }

  before do
    allow(Google::Cloud::Storage).to receive(:default_credentials) { credentials }
    allow(Open3).to receive(:capture3) { ["out", "err", status] }
  end

  it "returns gsutil wrapper" do
    expect(gsutil).to be_a(described_class)
  end

  context "with valid credentials file" do
    it_behaves_like "successfull gsutil upload"
  end

  context "with valid credentials json" do
    let(:credentials) { { google: :key } }
    let(:credentials_file) { "tmp_cred_file" }
    let(:tmp_file) { instance_double(File, write: nil, close: nil, path: credentials_file) }

    before do
      allow(Tempfile).to receive(:create).with("auth").and_yield(tmp_file)
    end

    it_behaves_like "successfull gsutil upload"
  end

  context "with invalid credentials" do
    let(:credentials) { "non-existing-file" }

    it_behaves_like "unsuccessful initialization"
  end

  context "with missing gsutil executable" do
    let(:command_status) { false }

    before do
      allow(Open3).to receive(:capture3).with("which gsutil") { ["out", "err", status] }
    end

    it_behaves_like "unsuccessful initialization"
  end
end
