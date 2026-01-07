import {Command, Flags} from '@oclif/core'
import {InferredFlags} from '@oclif/core/interfaces'
import {existsSync, writeFileSync} from 'node:fs'
import os from 'node:os'
import path from 'node:path'

import {UpdatePRMode} from '../../types/index.js'
import {getAllureResultsPaths} from '../../utils/glob.js'
import {globalConfig} from '../../utils/global-config.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'
import {getAllureConfig} from '../allure/config.js'
import {ReportGenerator} from '../allure/report-generator.js'
import {createReportSection} from '../ci/update-workflow.js'
import {ciInfo, isCI, isPR} from '../ci/utils.js'
import {BaseCloudUploader} from '../uploader/cloud/base.js'

export abstract class BaseUploadCommand extends Command {
  private _resultPaths: string[] | undefined
  static baseFlags = {
    // Allure report flags
    'results-glob': Flags.string({
      char: 'r',
      default: './**/allure-results',
      description: 'Glob pattern for allure results directories',
      env: 'ALLURE_RESULTS_GLOB',
    }),
    config: Flags.string({
      char: 'c',
      description: 'The path to allure config file. Options provided here will override CLI flags',
      env: 'ALLURE_CONFIG',
    }),
    'report-name': Flags.string({
      description: 'Custom report name in Allure report',
      env: 'ALLURE_REPORT_NAME',
    }),
    output: Flags.string({
      char: 'o',
      description: 'Directory to generate the Allure report into',
      env: 'ALLURE_OUTPUT',
    }),
    'global-allure-exec': Flags.boolean({
      description: 'Use globally installed allure executable instead of the packaged one',
      env: 'ALLURE_GLOBAL_ALLURE_EXEC',
      default: false,
    }),

    // CI integration flags
    'ci-report-title': Flags.string({
      default: 'Allure Report',
      description: 'Title for PR comment/description section',
      env: 'ALLURE_CI_REPORT_TITLE',
    }),
    'update-pr': Flags.string({
      description: 'Update PR with a section containing the report URL',
      env: 'ALLURE_UPDATE_PR',
      options: ['comment', 'description', 'actions'],
    }),
    'add-summary': Flags.boolean({
      default: false,
      description: 'Add test summary table to section in PR',
      env: 'ALLURE_SUMMARY',
    }),
    'collapse-summary': Flags.boolean({
      default: false,
      description: 'Create collapsible summary section in PR',
      env: 'ALLURE_COLLAPSE_SUMMARY',
    }),
    'flaky-warning-status': Flags.boolean({
      default: false,
      description: 'Mark run with ! status if flaky tests found',
      env: 'ALLURE_FLAKY_WARNING_STATUS',
    }),

    // General flags
    color: Flags.boolean({
      allowNo: true,
      description: 'Force color output',
      env: 'ALLURE_COLOR',
    }),
    debug: Flags.boolean({
      default: false,
      description: 'Print debug log output',
      env: 'ALLURE_DEBUG',
    }),
    'ignore-missing-results': Flags.boolean({
      default: false,
      description: 'Ignore missing allure results and exit without error if no result paths found',
      env: 'ALLURE_IGNORE_MISSING_RESULTS',
    }),
  }

  protected get allureResultsPaths() {
    return this._resultPaths
  }

  protected isColorEnabled(color: boolean) {
    return color ?? process.stdout.isTTY
  }

  protected async initConfig(): Promise<InferredFlags<typeof BaseUploadCommand.baseFlags>> {
    const {flags} = await this.parse(this.constructor as typeof BaseUploadCommand)
    const baseDir = path.join(isCI ? './' : os.tmpdir(), 'allure-report-publisher')
    const globalConfigOptions = {
      color: this.isColorEnabled(flags.color),
      debug: flags.debug,
      output: flags.output ?? path.join(baseDir, 'allure-report'),
      baseDir,
    }
    logger.debug(`Initializing global config with options: ${JSON.stringify(globalConfigOptions)}`)
    globalConfig.initialize(globalConfigOptions)

    return flags
  }

  protected async validateInputs(flags: InferredFlags<typeof BaseUploadCommand.baseFlags>) {
    if (flags.config) {
      const ext = path.extname(flags.config).toLowerCase()
      const supportedExts = ['.json', '.yaml', '.yml', '.mjs', '.cjs', '.js']
      if (!supportedExts.includes(ext)) {
        throw new Error(`Unsupported config file format: ${ext}\nSupported formats are: ${supportedExts.join(', ')}`)
      }

      if (existsSync(flags.config) === false) {
        throw new Error(`Config file not found at path: ${flags.config}`)
      }
    }

    logger.section('Checking for allure results directories')
    const resultPaths = await this.getAllureResults(flags['results-glob'], flags['ignore-missing-results'])
    if (resultPaths === undefined) this.exit(0)
  }

  protected async getAllureResults(resultsGlob: string, ignoreMissingResults: boolean): Promise<string[] | undefined> {
    if (this._resultPaths !== undefined) return this._resultPaths

    this._resultPaths = await spin(
      getAllureResultsPaths(resultsGlob, ignoreMissingResults),
      `scanning allure results directories`,
      {ignoreError: ignoreMissingResults},
    )

    return this._resultPaths
  }

  protected async createExecutorJson(reportUrl: string) {
    for (const resultPath of this._resultPaths || []) {
      const executorJson = path.join(resultPath, 'executor.json')
      if (!existsSync(executorJson)) continue

      logger.debug(`Creating executor.json at path: ${executorJson}`)
      writeFileSync(executorJson, JSON.stringify(ciInfo?.executorJson(reportUrl), null, 2))
    }
  }
}

export abstract class BaseCloudUploadCommand extends BaseUploadCommand {
  static examples = [
    '<%= config.bin %> <%= command.id %> --results-glob="path/to/allure-results" --bucket=my-bucket',
    '<%= config.bin %> <%= command.id %> --results-glob="path/to/allure-results" --bucket=my-bucket --update-pr=comment --summary=behaviors',
  ]
  static baseFlags = {
    ...BaseUploadCommand.baseFlags,
    bucket: Flags.string({
      char: 'b',
      description: 'Cloud storage bucket name',
      env: 'ALLURE_BUCKET',
      required: true,
    }),
    prefix: Flags.string({
      char: 'p',
      description: 'Prefix for report path in cloud storage',
      env: 'ALLURE_PREFIX',
    }),
    'base-url': Flags.string({
      description: 'Custom base URL for report links',
      env: 'ALLURE_BASE_URL',
    }),
    'copy-latest': Flags.boolean({
      default: false,
      description: 'Keep copy of latest run report at base prefix',
      env: 'ALLURE_COPY_LATEST',
    }),
    parallel: Flags.integer({
      default: 8,
      description: 'Number of parallel threads for upload',
      env: 'ALLURE_PARALLEL',
    }),
  }

  protected get storageType(): string {
    return this.constructor.name.toLowerCase()
  }

  protected abstract getUploader(opts: {
    bucket: string
    copyLatest: boolean
    parallel: number
    historyPath: string
    output: string
    plugins: string[]
    baseUrl?: string
    prefix?: string
  }): BaseCloudUploader

  protected async initConfig() {
    const flags = (await super.initConfig()) as InferredFlags<typeof BaseCloudUploadCommand.baseFlags>
    globalConfig.parallel = flags.parallel

    return flags
  }

  protected async validateInputs(flags: InferredFlags<typeof BaseCloudUploadCommand.baseFlags>) {
    if (flags['base-url']) {
      try {
        // eslint-disable-next-line no-new
        new URL(flags['base-url'])
      } catch {
        throw new Error(
          `Invalid base URL: ${flags['base-url']}\nBase URL must be a valid URL starting with http:// or https://`,
        )
      }
    }

    if (flags.parallel < 1) {
      throw new Error(`Invalid parallel threads: ${flags.parallel}\nParallel threads must be >= 1`)
    }

    await super.validateInputs(flags)
  }

  async run(): Promise<void> {
    const flags = await this.initConfig()
    const updateMode = flags['update-pr'] as UpdatePRMode

    try {
      await this.validateInputs(flags)

      logger.section('Generating allure report')
      const allureConfig = getAllureConfig({
        configPath: flags.config,
        reportName: flags['report-name'],
        resultsGlob: flags['results-glob'],
      })
      const uploader = this.getUploader({
        bucket: flags.bucket!,
        baseUrl: flags['base-url'],
        copyLatest: flags['copy-latest'],
        prefix: flags.prefix,
        parallel: flags.parallel,
        output: await allureConfig.outputPath(),
        historyPath: await allureConfig.historyPath(),
        plugins: await allureConfig.plugins(),
      })

      await spin(uploader.downloadHistory(), 'downloading previous run history', {ignoreError: true})

      // legacy executor.json for allure2 plugin
      if (isCI && (await allureConfig.plugins()).includes('allure2')) {
        await spin(this.createExecutorJson(uploader.reportUrl()), 'creating executor.json files')
      }

      const reportGenerator = new ReportGenerator(allureConfig, flags['global-allure-exec'])
      await reportGenerator.execute()

      logger.section(`Uploading report to ${this.storageType}`)
      await uploader.upload()

      if (ciInfo && isPR && updateMode) {
        await createReportSection({
          reportUrl: uploader.reportUrl(),
          summary: reportGenerator.summary(),
          ciReportTitle: flags['ci-report-title'],
          addSummary: flags['add-summary'],
          collapseSummary: flags['collapse-summary'],
          flakyWarningStatus: flags['flaky-warning-status'],
          ignoreError: true,
          updateMode,
        })
      }

      logger.section('Report URLs')
      uploader.outputReportUrls()
    } catch (error) {
      this.error(error as Error, {exit: 1})
    }
  }
}
