module Publisher
  module Commands
    # Common arguments and options definition
    #
    module CommonOptions
      def self.included(mod)
        mod.instance_eval do
          option :color, default: false, type: :boolean, desc: "Force color output"
        end
      end
    end
  end
end
