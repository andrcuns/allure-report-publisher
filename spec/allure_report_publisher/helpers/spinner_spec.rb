RSpec.describe Publisher::Helpers::Spinner, epic: "helpers" do
  let(:spinner_message) { "Spinner message!" }
  let(:tty) { true }
  let(:pastel) { Pastel.new(enabled: true) }
  let(:success_mark) { pastel.decorate(TTY::Spinner::TICK, :green) }
  let(:error_mark_red) { pastel.decorate(TTY::Spinner::CROSS, :red) }
  let(:error_mark_yellow) { pastel.decorate(TTY::Spinner::CROSS, :yellow) }
  let(:error_message) { "failed\nError" }

  let(:spinner) do
    instance_double("TTY::Spinner", auto_spin: nil, stop: nil, success: nil, error: nil, tty?: tty)
  end
  let(:fake) do
    double("fake", run: nil)
  end

  before do
    allow(TTY::Spinner).to receive(:new) { spinner }
  end

  context "without errors" do
    it "starts spinner and executed and yields block" do
      described_class.spin(spinner_message) { fake.run }

      aggregate_failures do
        expect(spinner).to have_received(:auto_spin)
        expect(spinner).to have_received(:success).with("done")
        expect(fake).to have_received(:run)
      end
    end

    it "prints custom done message" do
      described_class.spin(spinner_message, done_message: "custom done") { fake.run }

      expect(spinner).to have_received(:success).with("custom done")
    end
  end

  context "with exit_on_error: true" do
    it "creates instance with red error mark" do
      described_class.spin(spinner_message) { fake.run }

      expect(TTY::Spinner).to have_received(:new).with(
        "[:spinner] #{spinner_message} ...",
        format: :dots,
        success_mark: success_mark,
        error_mark: error_mark_red
      )
    end

    it "exits program on error and prints red error message" do
      aggregate_failures do
        expect { described_class.spin(spinner_message) { raise("Error") } }.to raise_error(SystemExit)
        expect(spinner).to have_received(:error).with(pastel.decorate(error_message, :red))
      end
    end
  end

  context "with exit_on_error: false" do
    it "creates instance with yellow error mark" do
      described_class.spin(spinner_message, exit_on_error: false) { fake.run }

      expect(TTY::Spinner).to have_received(:new).with(
        "[:spinner] #{spinner_message} ...",
        format: :dots,
        success_mark: success_mark,
        error_mark: error_mark_yellow
      )
    end

    it "does not exit program on error and prints yellow error message" do
      described_class.spin(spinner_message, exit_on_error: false) { raise("Error") }
      expect(spinner).to have_received(:error).with(pastel.decorate(error_message, :yellow))
    end
  end

  context "without tty" do
    let(:tty) { false }

    it "prints plain success message with default done message" do
      aggregate_failures do
        expect { described_class.spin(spinner_message) { fake.run } }.to(
          output("[#{success_mark}] #{spinner_message} ... done\n").to_stdout
        )
        expect(spinner).to have_received(:stop)
      end
    end

    it "prints plain success message with custom done message" do
      aggregate_failures do
        expect { described_class.spin(spinner_message, done_message: "custom done") { fake.run } }.to(
          output("[#{success_mark}] #{spinner_message} ... custom done\n").to_stdout
        )
        expect(spinner).to have_received(:stop)
      end
    end

    it "prints plain red error message and exits" do
      aggregate_failures do
        expect do
          expect { described_class.spin(spinner_message) { raise("Error") } }.to raise_error(SystemExit)
        end.to output("[#{error_mark_red}] #{spinner_message} ... #{pastel.decorate(error_message, :red)}\n").to_stdout
        expect(spinner).to have_received(:stop)
      end
    end

    it "prints plain yellow error message and doesnt exit" do
      aggregate_failures do
        expect { described_class.spin(spinner_message, exit_on_error: false) { raise("Error") } }.to(
          output("[#{error_mark_yellow}] #{spinner_message} ... #{pastel.decorate(error_message, :yellow)}\n").to_stdout
        )
        expect(spinner).to have_received(:stop)
      end
    end
  end
end
