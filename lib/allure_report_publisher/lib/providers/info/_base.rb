require "singleton"

module Publisher
  module Providers
    module Info
      # Base class for CI executor info
      #
      class Base
        # CI Provider executor info
        #
        # @param [String] report_url
        # @return [Hash]
        def executor(_report_url)
          raise("Not implemented!")
        end

        # Running on pull request/merge request
        #
        # @return [Boolean]
        def pr?
          raise("Not implemented!")
        end

        # Pipeline run id
        #
        # @return [Integer]
        def run_id
          raise("Not implemented!")
        end
      end
    end
  end
end
