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

      # Summary table generator
      #
      # @param [String] report_path
      # @param [String] summary_type
      def initialize(report_path, summary_type)
        @report_path = report_path
        @summary_type = summary_type
      end

      # Get summary table
      #
      # @param [String] report_path
      # @param [String] summary_type
      # @return [Terminal::Table]
      def self.get(report_path, summary_type)
        new(report_path, summary_type).summary_table
      end

      # Summary table
      #
      # @return [Terminal::Table]
      def summary_table
        return short_summary_table if summary_type == TOTAL

        expanded_summary_table
      end

      private

      attr_reader :report_path, :summary_type

      # Expanded summary table
      #
      # @return [Terminal::Table]
      def expanded_summary_table
        table(summary_data.map { |name, summary| [name, *summary.values, summary[:failed].zero? ? "✅" : "❌"] })
      end

      # Short summary table
      #
      # @return [Terminal::Table]
      def short_summary_table
        sum = summary_data.values.each_with_object({ passed: 0, failed: 0, skipped: 0 }) do |entry, hsh|
          hsh[:passed] += entry[:passed]
          hsh[:failed] += entry[:failed]
          hsh[:skipped] += entry[:skipped]
        end

        table([["Total", sum[:passed], sum[:failed], sum[:skipped], sum[:failed].zero? ? "✅" : "❌"]])
      end

      # Summary terminal table
      #
      # @param [Array] rows
      # @return [Terminal::Table]
      def table(rows)
        Terminal::Table.new do |table|
          table.title = "#{summary_type} summary"
          table.headings = ["", "passed", "failed", "skipped", "result"]
          table.rows = rows
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
      def fetch_results(entry, summary = { passed: 0, failed: 0, skipped: 0 })
        entry[:children].each { |item| fetch_results(item, summary) } if entry.key?(:children)

        summary[:passed] += 1 if entry[:status] == "passed"
        summary[:skipped] += 1 if entry[:status] == "skipped"
        summary[:failed] += 1 if %w[failed broken].include?(entry[:status])

        summary
      end
    end
  end
end
