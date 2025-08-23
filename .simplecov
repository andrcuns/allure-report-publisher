# frozen_string_literal: true

return unless ENV["COVERAGE"] || ENV["COV_HTML_REPORT"]

require "simplecov-console"
require "simplecov-cobertura"

SimpleCov.start do
  add_filter ["/spec/", "/bin/"]
  enable_coverage :branch

  formatter(
    [].then do |formatters|
      formatters << SimpleCov::Formatter::Console
      formatters << SimpleCov::Formatter::HTMLFormatter if ENV["COV_HTML_REPORT"]
      formatters << SimpleCov::Formatter::CoberturaFormatter if ENV["CI"]
      SimpleCov::Formatter::MultiFormatter.new(formatters)
    end
  )
end
