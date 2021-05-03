RSpec.shared_context("with stdout capture") do
  let(:stdout) { StringIO.new }

  # rubocop:disable RSpec/ExpectOutput
  around do |example|
    orig_stdout = $stdout
    $stdout = stdout

    example.run

    $stdout = orig_stdout
  end
  # rubocop:enable RSpec/ExpectOutput
end
