module Publisher
  # CI provider utilities
  #
  module CI
    # Detect CI provider
    #
    # @return [Publisher::CI::Base]
    def self.provider
      return GithubActions if ENV["GITHUB_WORKFLOW"]
    end

    # Base class for CI executor info
    #
    class Base
      EXECUTOR_JSON = "executor.json".freeze

      def initialize(results_path, report_url)
        @results_path = results_path
        @report_url = report_url
      end

      # :nocov:

      # Get ci run ID without creating instance of ci provider
      #
      # @return [String]
      def self.run_id
        raise("Not implemented!")
      end
      # :nocov:

      # Write executor info file
      #
      # @return [void]
      def write_executor_info
        File.open("#{results_path}/#{EXECUTOR_JSON}", "w") do |file|
          file.write(executor_info.to_json)
        end
      end

      private

      attr_reader :results_path, :report_url

      # :nocov:

      # Get executor info
      #
      # @return [Hash]
      def executor_info
        raise("Not implemented!")
      end
      # :nocov:

      # CI run id
      #
      # @return [String]
      def run_id
        self.class.run_id
      end
    end
  end
end
