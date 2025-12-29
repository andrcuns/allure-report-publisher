import type {InferredFlags} from '@oclif/core/interfaces'

import {Args, Command, Flags} from '@oclif/core'

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
    bucket: Flags.string({
      char: 'b',
      description: 'Cloud storage bucket name (required for s3/gcs)',
      env: 'ALLURE_BUCKET',
      required: false,
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
      description: 'Keep copy at base prefix (ignored for gitlab-artifacts)',
      env: 'ALLURE_COPY_LATEST',
    }),
    // Debug
    debug: Flags.boolean({
      default: false,
      description: 'Print debug output',
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
    // Optional configuration
    output: Flags.string({
      char: 'o',
      description:
        'Output directory for generated report (default: temp dir for cloud, "allure-report" for gitlab-artifacts)',
      env: 'ALLURE_OUTPUT',
    }),
    // Performance
    parallel: Flags.integer({
      default: 8,
      description: 'Number of parallel threads for upload',
      env: 'ALLURE_PARALLEL',
    }),

    prefix: Flags.string({
      char: 'p',
      description: 'Prefix for report path in cloud storage (ignored for gitlab-artifacts)',
      env: 'ALLURE_PREFIX',
    }),
    // Report customization
    reportName: Flags.string({
      aliases: ['report-name'],
      description: 'Custom report name in Allure report',
      env: 'ALLURE_REPORT_NAME',
    }),
    reportTitle: Flags.string({
      aliases: ['report-title'],
      default: 'Allure Report',
      description: 'Title for PR comment/description section',
      env: 'ALLURE_REPORT_TITLE',
    }),
    // Core required flags
    resultsGlob: Flags.string({
      aliases: ['results-glob'],
      char: 'r',
      description: 'Glob pattern for allure results directories',
      env: 'ALLURE_RESULTS_GLOB',
      required: true,
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
    // PR integration
    updatePr: Flags.string({
      aliases: ['update-pr'],
      description: 'Update PR with report URL (comment/description/actions)',
      env: 'ALLURE_UPDATE_PR',
      options: ['comment', 'description', 'actions'],
    }),
  }
  // Allow extra arguments after '--'
  static override strict = false

  async run(): Promise<void> {
    const {args, flags} = await this.parse(Upload)

    const colorEnabled = flags.color ?? process.stdout.isTTY
    config.initialize({color: colorEnabled, debug: flags.debug})

    try {
      const storageType = args.type

      await this.validateInputs(storageType, flags)
      const resultPaths = await this.getAllureResults(flags.resultsGlob, flags.ignoreMissingResults)

      if (resultPaths === undefined) return

      // TODO: Generate report
      logger.section('Generating allure report')
      logger.info('Report generation not yet implemented')

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
  }

  private async getAllureResults(resultsGlob: string, ignoreMissingResults: boolean): Promise<string[] | undefined> {
    logger.section('Scanning for allure results')
    const resultPaths = await spin(
      getAllureResultsPaths(resultsGlob),
      `Fetching results files using glob '${resultsGlob}'`,
      {ignoreError: ignoreMissingResults},
    )

    return resultPaths
  }
}
