RSpec.shared_context("with mock helper") do
  let(:spinner) { instance_double("TTY::Spinner", auto_spin: nil, success: nil, error: nil) }

  before do
    allow(TTY::Spinner).to receive(:new) { spinner }
  end
end
