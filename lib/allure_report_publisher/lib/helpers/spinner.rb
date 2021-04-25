require "tty-spinner"

module Publisher
  # Helpers
  #
  module Helpers
    # Spinner helper class
    #
    class Spinner
      include Helpers

      def initialize(spinner_message, exit_on_error: true)
        @spinner_message = spinner_message
        @exit_on_error = exit_on_error
      end

      # Run code block inside spinner
      #
      # @param [String] spinner_message
      # @param [String] done_message
      # @param [Boolean] exit_on_error
      # @param [Proc] &block
      # @return [void]
      def self.spin(spinner_message, done_message: "done", exit_on_error: true, &block)
        new(spinner_message, exit_on_error: exit_on_error).spin(done_message, &block)
      end

      # Run code block inside spinner
      #
      # @param [String] done_message
      # @return [Boolean]
      def spin(done_message = "done")
        spinner.auto_spin
        yield
        spinner_success(done_message)
      rescue StandardError => e
        spinner_error(e.message)
        exit(1) if exit_on_error
      end
    end

    private

    attr_reader :spinner_message, :exit_on_error

    # Error message color
    #
    # @return [Symbol]
    def error_color
      @error_color ||= exit_on_error ? :red : :yellow
    end

    # Success mark
    #
    # @return [String]
    def success_mark
      @success_mark ||= colorize(TTY::Spinner::TICK, :green)
    end

    # Error mark
    #
    # @return [String]
    def error_mark
      colorize(TTY::Spinner::CROSS, error_color)
    end

    # Spinner instance
    #
    # @return [TTY::Spinner]
    def spinner
      @spinner ||= TTY::Spinner.new(
        "[:spinner] #{spinner_message} ...",
        format: :dots,
        success_mark: success_mark,
        error_mark: error_mark
      )
    end

    # Check tty
    #
    # @return [Boolean]
    def tty?
      spinner.send(:tty?)
    end

    # Return spinner success
    #
    # @param [String] done_message
    # @return [void]
    def spinner_success(done_message)
      return spinner.success(done_message) if tty?

      spinner.stop
      puts("[#{success_mark}] #{spinner_message} ... #{done_message}")
    end

    # Return spinner error
    #
    # @param [String] error_message
    # @return [void]
    def spinner_error(error_message)
      return spinner.error(colorize(error_message, error_color)) if tty?

      spinner.stop
      puts("[#{error_mark}] #{spinner_message} ... #{error_message}")
    end
  end
end
