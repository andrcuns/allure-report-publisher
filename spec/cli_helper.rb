RSpec.shared_context("with cli helper") do
  # Execute command
  #
  # @param [Array] args
  # @return [Object]
  def run_cli(*args)
    Dry::CLI.new(Publisher::Commands).call(arguments: args)
  end
end
