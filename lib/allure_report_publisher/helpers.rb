module Allure
  module Publisher
    module Helpers
      # Log message to stdout
      #
      # @param [String] message
      # @param [String] color
      # @return [void]
      def log(message, color = "magenta")
        puts CLI::UI.fmt("{{#{color}:#{message}}}")
      end

      # Safe join path
      #
      # @param [Array<String>] *args
      # @return [String]
      def path(*args)
        File.join(args).to_s
      end

      def spin(message, auto_debrief: true, done_message: "#{message} ... done")
        CLI::UI::Spinner.spin(message, auto_debrief: auto_debrief) do |spinner|
          yield
          spinner.update_title(done_message)
        end
      end
    end
  end
end
