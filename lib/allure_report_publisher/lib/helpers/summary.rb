require "terminal-table"

module Publisher
  module Helpers
    # Test summary table generator
    #
    class Summary
      BEHAVIOR = "behaviors".freeze
      PACKAGES = "packages".freeze
      SUITES = "suites".freeze

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
        table_style = {
          border_left: false,
          border_right: false,
          border_top: false,
          border_bottom: false,
          all_separators: true
        }

        Terminal::Table.new(title: "#{summary_type} summary", style: table_style) do |table|
          table.headings = ["", "passed", "failed", "skipped", "result"]
          table.rows = summary_data.map do |name, summary|
            [name, *summary.values, summary[:failed].zero? ? "✅" : "❌"]
          end
        end
      end

      private

      attr_reader :report_path, :summary_type

      # Data json
      #
      # @return [Hash]
      def data_json
        @data_json ||= JSON.parse(
          File.read(File.join(report_path, "data", "#{summary_type}.json")),
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
