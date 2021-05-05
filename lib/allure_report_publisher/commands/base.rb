module Publisher
  module Commands
    # Common arguments and options definition
    #
    module CommonOptions
      def self.included(mod)
        mod.instance_eval do
          option :color, type: :boolean, desc: "Toggle color output, default: false"
          option :update_pr,
                 type: :boolean,
                 default: false,
                 desc: "Update pull request description with url to allure report"
          option :copy_latest,
                 type: :boolean,
                 default: false,
                 desc: "Keep copy of latest report at base prefix path"
        end
      end
    end
  end
end
