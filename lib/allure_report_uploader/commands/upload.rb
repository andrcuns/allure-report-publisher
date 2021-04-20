module Allure
  module Uploader
    module Commands
      # Upload allure report
      #
      class Upload < Dry::CLI::Command
        EXECUTOR_JSON = "executor.json".freeze
        ALLURE_REPORT_DIR = "allure-report".freeze

        desc "Generate and upload allure report"

        argument :result_glob, required: true, desc: "Allure results files glob"

        def call(results_glob:)
          @s3 = S3Helper.new
          @results_path = results_path
          @base_path = results_path.split("/").last
          @test_report_bucket = ENV["SCOUTRFP_AWS_S3_BUCKET_TEST_REPORTS"]
          @s3_run_report_path = "#{ENV['CI_PIPELINE_ID']}/allure/#{@base_path}"
          @s3_master_report_path = "#{ENV['CI_COMMIT_REF_NAME']}/allure/#{@base_path}"

          generate_and_upload
        end

        def generate_and_upload
          puts "\033[1;33m**Processing allure results - #{@results_path}**\033[0m"
          return puts "#{@results_path} doesn’t exist, skipping!" unless File.exist?(@results_path)

          add_executor_info
          add_history_info
          generate_report
          upload_report
        end

        private

        def report_url(path)
          "http://#{@test_report_bucket}.s3.amazonaws.com/#{path}/index.html"
        end

        def add_history_info
          puts "#Fetching history data#"
          %x(mc cp -r s3/#{@test_report_bucket}/#{@s3_master_report_path}/history #{@results_path} 2>&1)
        end

        def add_executor_info
          data = {
            name: "Gitlab", type: "gitlab", url: "https://#{ENV['CI_SERVER_HOST']}",
            buildOrder: ENV["CI_PIPELINE_ID"], buildName: @base_path, buildUrl: ENV["CI_PIPELINE_URL"],
            reportUrl: report_url(@s3_run_report_path), reportName: "AllureReport"
          }
          File.open("#{@results_path}/#{EXECUTOR_JSON}", "w") do |file|
            file.write(data.to_json)
          end
        end

        def generate_report
          puts "#Generating allure report#"
          system("allure generate -c -o #{ALLURE_REPORT_DIR} #{@results_path}")
        end

        def upload_report
          puts "#Uploading allure report#"
          Parallel.each([@s3_run_report_path, @s3_master_report_path]) do |path|
            @s3.store_files("*/", ALLURE_REPORT_DIR, path)
          end
          puts "Run report: #{report_url(@s3_run_report_path)}"
          puts "Master report: #{report_url(@s3_master_report_path)}"
        end
      end
    end
  end
end
