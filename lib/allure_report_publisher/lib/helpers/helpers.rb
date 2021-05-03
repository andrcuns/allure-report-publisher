require "pastel"
require "open3"

module Publisher
  # Helpers
  #
  module Helpers
    # Global instance of pastel
    #
    # @param [Boolean] force_color
    # @return [Pastel]
    def self.pastel(force_color: nil)
      @pastel ||= Pastel.new(enabled: force_color)
    end

    # Check allure cli is installed and executable
    #
    # @return [void]
    def self.validate_allure_cli_present
      _out, status = Open3.capture2("which allure")
      return if status.success?

      Helpers.error(
        "Allure cli is missing! See https://docs.qameta.io/allure/#_installing_a_commandline on how to install it!"
      )
    end

    # Colorize string
    #
    # @param [String] message
    # @param [Symbol] color
    # @return [String]
    def colorize(message, color)
      Helpers.pastel.decorate(message, color)
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
      warn colorize(message, :red)
      exit(1)
    end

    # Safe join path
    #
    # @param [Array<String>] *args
    # @return [String]
    def path(*args)
      File.join(args).to_s
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

    module_function :colorize, :log, :error, :path, :execute_shell
  end
end
