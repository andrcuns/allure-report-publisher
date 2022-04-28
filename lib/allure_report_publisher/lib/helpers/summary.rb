require "terminal-table"

module Publisher
  module Helpers
    # Test summary table generator
    #
    class Summary
      BEHAVIORS = "behaviors".freeze
      PACKAGES = "packages".freeze
      SUITES = "suites".freeze
      TOTAL = "total".freeze
      MARKDOWN = :markdown
      ASCII = :ascii

      # Summary table generator
      #
      # @param [String] report_path
      # @param [String] summary_type
      # @param [String] markdown
      def initialize(report_path, summary_type, table_type = ASCII)
        @report_path = report_path
        @summary_type = summary_type || TOTAL
        @table_type = table_type
      end

      # Summary table
      #
      # @return [String]
      def table
        summary = if summary_type == TOTAL
                    terminal_table { |table| table << short_summary }
                  else
                    terminal_table do |table|
                      expanded_summary.each { |row| table << row }
                      table << :separator
                      table << short_summary
                    end
                  end

        return summary.to_s if table_type == MARKDOWN

        "```markdown\n#{summary}\n```"
      end

      # Test run status emoji
      #
      # @return [String]
      def status
        short_summary.last
      end

      private

      attr_reader :report_path, :summary_type, :table_type

      # Expanded summary table
      #
      # @return [Array<Array>]
      def expanded_summary
        @expanded_summary ||= summary_data.map do |name, summary|
          [name, *summary.values, status_icon(summary[:passed], summary[:failed], summary[:flaky])]
        end
      end

      # Short summary table
      #
      # @return [Array<String>]
      def short_summary
        return @short_summary if defined?(@short_summary)

        sum = summary_data.values.each_with_object({ passed: 0, failed: 0, skipped: 0, flaky: 0 }) do |entry, hsh|
          hsh[:passed] += entry[:passed]
          hsh[:failed] += entry[:failed]
          hsh[:skipped] += entry[:skipped]
          hsh[:flaky] += entry[:flaky]
        end

        @short_summary = [
          "Total",
          sum[:passed],
          sum[:failed],
          sum[:skipped],
          sum[:flaky],
          status_icon(sum[:passed], sum[:failed], sum[:flaky])
        ]
      end

      # Status icon based on run results
      #
      # @param [Integer] passed
      # @param [Integer] failed
      # @param [Integer] flaky
      # @return [String]
      def status_icon(passed, failed, flaky)
        return "➖" if passed.zero? && failed.zero?
        return flaky.zero? ? "✅" : "❗" if failed.zero?

        "❌"
      end

      # Summary terminal table
      #
      # @return [Terminal::Table]
      def terminal_table
        Terminal::Table.new do |table|
          table.title = "#{summary_type} summary"
          table.style = { border: table_type }
          table.headings = ["", "passed", "failed", "skipped", "flaky", "result"]
          yield(table)
        end
      end

      # Data json
      #
      # @return [Hash]
      def data_json
        @data_json ||= JSON.parse(
          File.read(File.join(report_path, "data", "#{summary_type == TOTAL ? SUITES : summary_type}.json")),
          symbolize_names: true
        )
      end

      # Summary data
      #
      # @return [Hash<Hash>]
      def summary_data
        data_json[:children].each_with_object({}) do |entry, result|
          result[entry[:name]] = fetch_results(entry)
        end
      end

      # Fetch test results
      #
      # @param [Hash] entry
      # @param [Hash] summary
      # @return [Hash]
      def fetch_results(entry, summary = { passed: 0, failed: 0, skipped: 0, flaky: 0 })
        entry[:children].each { |item| fetch_results(item, summary) } if entry.key?(:children)

        summary[:passed] += 1 if entry[:status] == "passed"
        summary[:skipped] += 1 if entry[:status] == "skipped"
        summary[:flaky] += 1 if entry[:flaky]
        summary[:failed] += 1 if %w[failed broken].include?(entry[:status])

        summary
      end
    end
  end
end
