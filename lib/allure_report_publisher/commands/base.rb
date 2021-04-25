module Publisher
  module Commands
    # Common arguments and options definition
    #
    module CommonOptions
      def self.included(mod)
        mod.instance_eval do
          option :color, type: :boolean, desc: "Toggle color output"
        end
      end
    end
  end
end
