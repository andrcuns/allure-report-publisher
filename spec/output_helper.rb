RSpec.shared_context("with output capture") do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  # rubocop:disable RSpec/ExpectOutput
  around do |example|
    orig_stdout = $stdout
    orig_stderr = $stderr
    $stdout = stdout
    $stderr = stderr

    example.run

    $stdout = orig_stdout
    $stderr = orig_stderr
  end
  # rubocop:enable RSpec/ExpectOutput
end
