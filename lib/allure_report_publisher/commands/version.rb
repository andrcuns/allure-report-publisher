module Publisher
  module Commands
    # Print version number
    #
    class Version < Dry::CLI::Command
      desc "Print version"

      def call(*)
        puts Publisher::VERSION
      end
    end
  end
end
