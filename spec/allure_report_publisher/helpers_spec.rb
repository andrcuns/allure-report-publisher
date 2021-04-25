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

  context "with spinner" do
    it "outputs spinning and done message" do
      helpers.spin("message", done_message: "done message") { fake.run }

      aggregate_failures do
        expect(spinner).to have_received(:auto_spin)
        expect(spinner).to have_received(:success).with("done message")
        expect(fake).to have_received(:run)
      end
    end

    it "exits on error and prints error message" do
      expect { helpers.spin("message") { raise("some error!") } }.to raise_error(SystemExit)

      aggregate_failures do
        expect(spinner).to have_received(:error).with("colorized string")
        expect(pastel).to have_received(:decorate).with("some error!", :red)
      end
    end

    it "prints warning and doesnt exit on exit_on_failure: false" do
      helpers.spin("message", exit_on_error: false) { raise("some error!") }

      aggregate_failures do
        expect(spinner).to have_received(:error).with("colorized string")
        expect(pastel).to have_received(:decorate).with("some error!", :yellow)
      end
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
