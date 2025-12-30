import type {InferredFlags} from '@oclif/core/interfaces'

import {Args, Command, Flags} from '@oclif/core'
import {existsSync} from 'node:fs'
import path from 'node:path'

import {getAllureConfig} from '../../lib/allure/config.js'
import {ReportGenerator} from '../../lib/allure/report-generator.js'
import {config} from '../../utils/config.js'
import {getAllureResultsPaths} from '../../utils/glob.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'

export default class Upload extends Command {
  static override args = {
    type: Args.string({
      description: 'Cloud storage provider type',
      options: ['s3', 'gcs', 'gitlab-artifacts'],
      required: true,
    }),
  }
  static override description = 'Generate and upload allure report to cloud storage'
  static override examples = [
    '<%= config.bin %> <%= command.id %> s3 --results-glob="path/to/allure-results" --bucket=my-bucket',
    '<%= config.bin %> <%= command.id %> gcs --results-glob="paths/to/**/allure-results" --bucket=my-bucket --prefix=my-project/prs',
    '<%= config.bin %> <%= command.id %> gitlab-artifacts --results-glob="paths/to/**/allure-results"',
    '<%= config.bin %> <%= command.id %> s3 --results-glob="path/to/allure-results" --bucket=my-bucket --update-pr=comment --summary=behaviors',
  ]
  static override flags = {
    baseUrl: Flags.string({
      aliases: ['base-url'],
      description: 'Custom base URL for report links',
      env: 'ALLURE_BASE_URL',
    }),
    resultsGlob: Flags.string({
      aliases: ['results-glob'],
      char: 'r',
      default: './**/allure-results',
      description: 'Glob pattern for allure results directories',
      env: 'ALLURE_RESULTS_GLOB',
    }),
    bucket: Flags.string({
      char: 'b',
      description: 'Cloud storage bucket name (required for s3/gcs)',
      env: 'ALLURE_BUCKET',
    }),
    prefix: Flags.string({
      char: 'p',
      description: 'Prefix for report path in cloud storage (ignored for gitlab-artifacts)',
      env: 'ALLURE_PREFIX',
    }),
    config: Flags.string({
      char: 'c',
      description: 'The path to allure config file (only .json or .yaml are supported)',
      env: 'ALLURE_CONFIG_PATH',
    }),
    reportName: Flags.string({
      aliases: ['report-name'],
      description: 'Custom report name in Allure report (ignored with config-path)',
      env: 'ALLURE_REPORT_NAME',
    }),
    ciReportTitle: Flags.string({
      aliases: ['ci-report-title'],
      default: 'Allure Report',
      description: 'Title for PR comment/description section',
      env: 'ALLURE_CI_REPORT_TITLE',
    }),
    summary: Flags.string({
      default: 'total',
      description: 'Add test summary table to PR',
      env: 'ALLURE_SUMMARY',
      options: ['behaviors', 'suites', 'packages', 'total'],
    }),
    summaryTableType: Flags.string({
      aliases: ['summary-table-type'],
      default: 'ascii',
      description: 'Summary table format',
      env: 'ALLURE_SUMMARY_TABLE_TYPE',
      options: ['ascii', 'markdown'],
    }),
    updatePr: Flags.string({
      aliases: ['update-pr'],
      description: 'Update PR with report URL (comment/description/actions)',
      env: 'ALLURE_UPDATE_PR',
      options: ['comment', 'description', 'actions'],
    }),

    // Boolean flags
    collapseSummary: Flags.boolean({
      aliases: ['collapse-summary'],
      default: false,
      description: 'Create collapsible summary section in PR',
      env: 'ALLURE_COLLAPSE_SUMMARY',
    }),
    color: Flags.boolean({
      allowNo: true,
      description: 'Force color output',
      env: 'ALLURE_COLOR',
    }),
    copyLatest: Flags.boolean({
      aliases: ['copy-latest'],
      default: false,
      description: 'Keep copy of latest run report at base prefix (ignored for gitlab-artifacts)',
      env: 'ALLURE_COPY_LATEST',
    }),
    debug: Flags.boolean({
      default: false,
      description: 'Print debug log output',
      env: 'ALLURE_DEBUG',
    }),
    flakyWarningStatus: Flags.boolean({
      aliases: ['flaky-warning-status'],
      default: false,
      description: 'Mark run with ! status if flaky tests found',
      env: 'ALLURE_FLAKY_WARNING_STATUS',
    }),
    ignoreMissingResults: Flags.boolean({
      aliases: ['ignore-missing-results'],
      default: false,
      description: 'Ignore missing allure results',
      env: 'ALLURE_IGNORE_MISSING_RESULTS',
    }),
    output: Flags.string({
      char: 'o',
      description:
        'Output directory for generated report (default: temp dir for cloud, "allure-report" for gitlab-artifacts)',
      env: 'ALLURE_OUTPUT',
    }),
    parallel: Flags.integer({
      default: 8,
      description: 'Number of parallel threads for upload',
      env: 'ALLURE_PARALLEL',
    }),
  }

  async run(): Promise<void> {
    const {args, flags} = await this.parse(Upload)

    const colorEnabled = flags.color ?? process.stdout.isTTY
    config.initialize({color: colorEnabled, debug: flags.debug})

    try {
      const storageType = args.type
      await this.validateInputs(storageType, flags)

      logger.section('Generating allure report')
      const resultPaths = await this.getAllureResults(flags.resultsGlob, flags.ignoreMissingResults)
      if (resultPaths === undefined) return

      const allureConfig = getAllureConfig(flags.config, flags.reportName)
      const reportGenerator = new ReportGenerator(flags.resultsGlob, allureConfig.configPath(), async () => {})
      logger.debug(`Using report plugins: ${(await allureConfig.plugins()).join(', ')}`)
      await reportGenerator.execute()

      // TODO: Upload report
      logger.section(`Uploading report to ${storageType}`)
      logger.info('Report upload not yet implemented')

      // TODO: Update PR if requested
      if (flags.updatePr) {
        logger.section('Updating PR/MR')
        logger.info('PR update not yet implemented')
      }

      logger.success('Command completed successfully')
    } catch (error) {
      logger.error((error as Error).message)
      this.exit(1)
    }
  }

  private async validateInputs(type: string, flags: InferredFlags<typeof Upload.flags>): Promise<void> {
    if (type !== 'gitlab-artifacts' && !flags.bucket) {
      throw new Error(
        `--bucket is required for storage type "${type}"\nOnly gitlab-artifacts does not require a bucket.`,
      )
    }

    if (flags.baseUrl) {
      try {
        // eslint-disable-next-line no-new
        new URL(flags.baseUrl)
      } catch {
        throw new Error(
          `Invalid base URL: ${flags.baseUrl}\nBase URL must be a valid URL starting with http:// or https://`,
        )
      }
    }

    if (flags.parallel < 1) {
      throw new Error(`Invalid parallel threads: ${flags.parallel}\nParallel threads must be >= 1`)
    }

    if (flags.config) {
      const ext = path.extname(flags.config).toLowerCase()
      const supportedExts = ['.json', '.yaml']
      if (!supportedExts.includes(ext)) {
        throw new Error(`Unsupported config file format: ${ext}\nSupported formats are: ${supportedExts.join(', ')}`)
      }

      if (existsSync(flags.config) === false) {
        throw new Error(`Config file not found at path: ${flags.config}`)
      }
    }
  }

  private async getAllureResults(resultsGlob: string, ignoreMissingResults: boolean): Promise<string[] | undefined> {
    const resultPaths = await spin(
      getAllureResultsPaths(resultsGlob, ignoreMissingResults),
      `scanning allure results directories`,
      {ignoreError: ignoreMissingResults},
    )

    return resultPaths
  }
}
