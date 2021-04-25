require "tty-spinner"
require "pastel"
require "open3"

module Publisher
  # General helpers
  #
  module Helpers
    # Colorize string
    #
    # @param [String] message
    # @param [Symbol] color
    # @return [String]
    def colorize(message, color)
      Pastel.new.decorate(message, color)
    end

    # Log message to stdout
    #
    # @param [String] message
    # @param [String] color
    # @return [void]
    def log(message, color = :magenta)
      puts colorize(message, color)
    end

    # Print error message and exit
    #
    # @param [String] message
    # @return [void]
    def error(message)
      puts colorize(message, :red)
      exit(1)
    end

    # Safe join path
    #
    # @param [Array<String>] *args
    # @return [String]
    def path(*args)
      File.join(args).to_s
    end

    # Execute code inside spinner
    #
    # @param [String] message
    # @param [String] done_message
    # @return [Boolean]
    def spin(message, done_message: "done", exit_on_error: true)
      spinner = TTY::Spinner.new(
        "[:spinner] #{message} ...",
        format: :dots,
        success_mark: colorize(TTY::Spinner::TICK, :green),
        error_mark: colorize(TTY::Spinner::CROSS, :red)
      )
      spinner.auto_spin
      yield
      spinner.success(done_message)
    rescue StandardError => e
      spinner.error(colorize(e.message, exit_on_error ? :red : :yellow))
      exit(1) if exit_on_error
    end

    # Execute shell command
    #
    # @param [String] command
    # @return [String] output
    def execute_shell(command)
      out, err, status = Open3.capture3(command)
      raise("Out:\n#{out}\n\nErr:\n#{err}") unless status.success?

      out
    end
  end
end
