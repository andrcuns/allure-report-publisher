require "tty-spinner"

module Publisher
  # Helpers
  #
  module Helpers
    # Spinner helper class
    #
    class Spinner
      include Helpers

      class Failure < StandardError; end

      def initialize(spinner_message, exit_on_error: true, debug: false)
        @spinner_message = spinner_message
        @exit_on_error = exit_on_error
        @debug = debug
      end

      # Run code block inside spinner
      #
      # @param [String] spinner_message
      # @param [String] done_message
      # @param [Boolean] exit_on_error
      # @param [Proc] &block
      # @return [void]
      def self.spin(
        spinner_message,
        done_message: "done",
        failed_message: "failed",
        exit_on_error: true,
        debug: false,
        &block
      )
        new(spinner_message, exit_on_error: exit_on_error, debug: debug).spin(done_message, failed_message, &block)
      end

      # Run code block inside spinner
      #
      # @param [String] done_message
      # @return [Boolean]
      def spin(done_message = "done", failed_message = "failed")
        spinner.auto_spin
        yield
        spinner_success(done_message)
      rescue StandardError => e
        spinner_error(e, done_message: failed_message)
        raise(Failure, e.message) if exit_on_error
      ensure
        print_debug
        Helpers.reset_debug_io!
      end
    end

    private

    attr_reader :spinner_message,
                :exit_on_error,
                :debug

    # Print debug contents
    #
    # @return [void]
    def print_debug
      return if !debug || Helpers.debug_io.string.empty?

      puts <<~OUT.strip
        == DEBUG LOG OUTPUT ==
        #{Helpers.debug_io.string.strip}
        == DEBUG LOG OUTPUT ==
      OUT
    end

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
    # @param [StandardError] error
    # @return [void]
    def spinner_error(error, done_message: "failed")
      message = [done_message, error.message]
      log_debug("Error: #{error.message}\n#{error.backtrace.join("\n")}")

      colored_message = colorize(message.compact.join("\n"), error_color)
      return spinner.error(colored_message) if tty?

      spinner.stop
      puts("[#{error_mark}] #{spinner_message} ... #{colored_message}")
    end
  end
end
