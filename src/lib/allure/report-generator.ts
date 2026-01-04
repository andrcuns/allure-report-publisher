import spawn, {SubprocessError} from 'nano-spawn'
import {readFileSync} from 'node:fs'

import {SummaryJson} from '../../types/index.js'
import {globPaths} from '../../utils/glob.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'
import {AllureConfig} from './config.js'

export class ReportGenerator {
  private readonly allureConfig
  private _outputPath: string | undefined
  private _generatedFiles: string[] | undefined

  constructor(allureConfig: AllureConfig) {
    this.allureConfig = allureConfig
  }

  public async execute() {
    await spin(this.generateReport(), 'generating report')
  }

  public summary() {
    if (!this._generatedFiles) throw new Error('Report has not been generated yet')

    const summaryFile = this._generatedFiles.find((file) => file.endsWith('summary.json'))
    if (!summaryFile) throw new Error('summary.json file not found in generated report files')

    return JSON.parse(readFileSync(summaryFile, 'utf8')) as SummaryJson
  }

  private get resultsGlob() {
    return this.allureConfig.resultsGlob
  }

  private async outputPath() {
    if (!this._outputPath) {
      this._outputPath = await this.allureConfig.outputPath()
    }

    return this._outputPath
  }

  private async generateReport() {
    const args = ['generate', this.resultsGlob, '-c', this.allureConfig.configPath(), '-o', await this.outputPath()]
    try {
      logger.debug(`Running allure with args: ${args.join(' ')}`)
      const result = await spawn('allure', args, {preferLocal: true})

      logger.debug('Allure report generation completed successfully')
      if (result.output.trim().length > 0) logger.debug(`Allure output:\n${result.output}`)

      this._generatedFiles = await globPaths(`${await this.outputPath()}/**/*`, {nodir: true})
      logger.debug(`Total report files for upload: ${this._generatedFiles.length}`)
    } catch (error) {
      const processError = error as SubprocessError
      logger.debug(`Command '${processError.command}' failed with exit code ${processError.exitCode}`)
      logger.debug(`Command execution time: ${processError.durationMs}ms`)
      throw new Error(
        `Allure report generation failed.\nMessage: ${processError.message}\nOutput: ${processError.output}`,
      )
    }
  }
}
