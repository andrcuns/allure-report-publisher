RSpec.describe Publisher::Helpers do
  subject(:helpers) { Helpers.new }

  include_context "with mock helper"

  let(:pastel) { double("Pastel", decorate: "colorized string") }
  let(:fake) { double("fake", run: nil) }

  before do
    stub_const("Helpers", Struct.new(:test) { include Publisher::Helpers })
    allow(Pastel).to receive(:new) { pastel }
  end

  context "with common helpers" do
    it "colorizes string" do
      helpers.colorize("message", :green)
      expect(pastel).to have_received(:decorate).with("message", :green)
    end

    it "returns joined path" do
      expect(helpers.path("path", "to", "file")).to eq("path/to/file")
    end
  end

  context "with successful shell command execution" do
    it "executes shell command" do
      aggregate_failures do
        expect(helpers.execute_shell("command")).to eq(cmd_out)
        expect(Open3).to have_received(:capture3).with("command")
      end
    end
  end

  context "with unsuccessful shell command execution" do
    let(:cmd_status) { false }

    it "raises error with command output" do
      expect { helpers.execute_shell("command") }.to raise_error("Out:\n#{cmd_out}\n\nErr:\n#{cmd_err}")
    end
  end
end
