require "pastel"
require "open3"

module Publisher
  # Helpers
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
