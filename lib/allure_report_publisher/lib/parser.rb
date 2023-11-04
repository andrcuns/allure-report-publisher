module Dry
  class CLI
    # Parser overload to support loading all options from environment variables
    #
    module Parser
      class InvalidEnvValue < StandardError; end

      ENV_VAR_PREFIX = "ALLURE_".freeze

      class << self
        def call(command, arguments, prog_name)
          original_arguments = arguments.dup
          parsed_options = {}

          OptionParser.new do |opts|
            command.options.each do |option|
              opts.on(*option.parser_options) do |value|
                parsed_options[option.name.to_sym] = value
              end
            end

            opts.on_tail("-h", "--help") do
              return Result.help
            end
          end.parse!(arguments)

          parsed_options = command
                           .default_params
                           .merge(load_options(command.options, parsed_options))

          parse_required_params(command, arguments, prog_name, parsed_options)
        rescue ::OptionParser::ParseError, InvalidEnvValue => e
          return Result.failure(e.message) if e.is_a?(InvalidEnvValue)

          Result.failure("ERROR: \"#{prog_name}\" was called with arguments \"#{original_arguments.join(' ')}\"")
        end

        private

        def load_options(options, parsed_options)
          options.each_with_object({}) do |option, opts|
            parsed_opt = parsed_options[option.name.to_sym]
            next opts[option.name.to_sym] = parsed_opt unless parsed_opt.nil?

            opts[option.name.to_sym] = option_from_env(option)
          end.compact
        end

        def option_from_env(option)
          name = "#{ENV_VAR_PREFIX}#{option.name.to_s.upcase}"
          value = ENV[name]
          return if value.nil? || value.empty?
          return if option.boolean? && !%w[true false].include?(value)

          validate_accepted_values(option, value)
          option.boolean? ? value == "true" : value
        end

        def validate_accepted_values(option, value)
          return unless option.values&.none? { |v| v.to_s == value }

          raise(InvalidEnvValue, "#{name} contains invalid value: '#{value}'")
        end
      end
    end
  end
end
