RSpec.describe Publisher::Helpers::Gsutil do
  subject(:gsutil) { described_class.init }

  let(:status) { instance_double(Process::Status, success?: command_status) }
  let(:command_status) { true }
  let(:credentials) { "spec/fixture/keyfile.json" }
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

  it "performs copy command" do
    gsutil.batch_copy(
      source_dir: report_path,
      destination_dir: destination_dir,
      bucket: bucket_name,
      cache_control: cache_control
    )

    expect(Open3).to have_received(:capture3).with([
      "gsutil -o 'Credentials:gs_service_key_file=#{credentials}' -m",
      "-h 'Cache-Control:private, max-age=#{cache_control}'",
      "cp -r #{report_path} gs://#{bucket_name}/#{destination_dir}"
    ].join(" "))
  end

  context "with valid credentials file" do
    it "initializes successfully" do
      expect(gsutil.valid?).to be(true)
    end
  end

  context "with valit credentials json" do
    let(:credentials) { { google: :key } }

    it "initializes successfully" do
      expect(gsutil.valid?).to be(true)
    end
  end

  context "with invalid credentials" do
    let(:credentials) { "non-existing-file" }

    it "initializes unsuccessfully" do
      expect(gsutil.valid?).to be(false)
    end
  end

  context "with missing gsutil executable" do
    let(:command_status) { false }

    before do
      allow(Open3).to receive(:capture3).with("which gsutil") { ["out", "err", status] }
    end

    it "initializes unsuccessfully" do
      expect(gsutil.valid?).to be(false)
    end
  end
end
