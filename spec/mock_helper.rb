RSpec.shared_context("with mock helper") do
  let(:spinner) { instance_double("TTY::Spinner", auto_spin: nil, success: nil, error: nil) }

  let(:status_fake) { double("status", success?: cmd_status) }
  let(:cmd_out) { "cmd-out" }
  let(:cmd_err) { "cmd-err" }
  let(:cmd_status) { true }

  before do
    allow(TTY::Spinner).to receive(:new) { spinner }
    allow(Open3).to receive(:capture3) { [cmd_out, cmd_err, status_fake] }
  end
end
