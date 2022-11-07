require "pastel"
require "open3"
require "logger"
require "stringio"

module Publisher
  # Helpers
  #
  module Helpers
    class ShellCommandFailure < StandardError; end

    class << self
      # Global instance of pastel
      #
      # @param [Boolean] force_color
      # @return [Pastel]
      def pastel(force_color: nil)
        @pastel ||= Pastel.new(enabled: force_color, eachline: "\n")
      end

      # Check allure cli is installed and executable
      #
      # @return [void]
      def allure_cli?
        execute_shell("which allure")
      rescue StandardError
        Helpers.error(
          "Allure cli is missing! See https://docs.qameta.io/allure/#_installing_a_commandline on how to install it!"
        )
      end

      # Debug logging session output
      #
      # @return [StringIO]
      def debug_io
        @debug_io ||= StringIO.new
      end

      # Clear debug log output
      #
      # @return [void]
      def reset_debug_io!
        @debug_io = nil
      end

      # Logger instance
      #
      # @return [Logger]
      def logger
        Logger.new(debug_io).tap do |logger|
          logger.datetime_format = "%Y-%m-%d %H:%M:%S"
          logger.formatter = proc { |_severity, time, _progname, msg| "[#{time}] #{msg}\n" }
        end
      end
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

    # Save debug message to be displayed later
    #
    # @param [String] message
    # @return [void]
    def log_debug(message)
      Helpers.logger.info(message)
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
    def execute_shell(command, mask: nil)
      loggable_command = mask ? command.gsub(mask, "***") : command
      log_debug("Executing command '#{loggable_command}'")
      out, err, status = Open3.capture3(command)

      cmd_output = []
      cmd_output << "Out: #{out}" unless out.empty?
      cmd_output << "Err: #{err}" unless err.empty?
      output = cmd_output.join("\n")

      unless status.success?
        err_msg = "Command '#{loggable_command}' failed!\n#{output}"
        err_msg = mask ? err_msg.gsub(mask, "***") : err_msg
        raise(ShellCommandFailure, err_msg)
      end

      mask ? output.gsub(mask, "***") : output
    end

    module_function :colorize, :log, :log_debug, :error, :path, :execute_shell
  end
end
