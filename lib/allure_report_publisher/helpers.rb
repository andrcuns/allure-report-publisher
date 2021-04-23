require "tty-spinner"
require "pastel"

module Allure
  module Publisher
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
      # @param [Boolean] auto_debrief
      # @param [String] done_message
      # @return [Boolean]
      def spin(message, done_message: "done")
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
        spinner.error(colorize(e.message, :red))
        exit(1)
      end
    end
  end
end
