RSpec.shared_context("with mock helper") do
  let(:spinner) { instance_double("Publisher::Helpers::Spinner") }

  let(:status_fake) { double("status", success?: cmd_status) }
  let(:cmd_out) { "cmd-out" }
  let(:cmd_err) { "cmd-err" }
  let(:cmd_status) { true }

  before do
    allow(Publisher::Helpers::Spinner).to receive(:new) { spinner }
    allow(spinner).to receive(:spin).and_yield
    allow(Open3).to receive(:capture3) { [cmd_out, cmd_err, status_fake] }
  end
end
