import spawn, {Result, SubprocessError} from 'nano-spawn'

import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'

export class ReportGenerator {
  private resultGlob
  private configPath
  private downloadHistory

  constructor(resultGlob: string, configPath: string, downloadHistory: () => Promise<void>) {
    this.resultGlob = resultGlob
    this.configPath = configPath
    this.downloadHistory = downloadHistory
  }

  public async execute() {
    await spin(this.downloadHistory(), "downloading previous run history")
    await spin(this.generateReport(), 'generating report')
  }

  private async generateReport() {
    const args = ['generate', this.resultGlob, '-c', this.configPath]
    logger.debug(`Running allure with args: ${args.join(' ')}`)
    return spawn('allure', args, {preferLocal: true})
      .then((result: Result) => {
        logger.debug('Allure report generation completed successfully')
        if (result.output.trim().length > 0) logger.debug(result.output)
      })
      .catch((error: SubprocessError) => {
        logger.debug(`Command '${error.command}' failed with exit code ${error.exitCode}`)
        logger.debug(`Command execution time: ${error.durationMs}ms`)
        throw new Error(`Allure report generation failed.\nMessage: ${error.message}\nOutput: ${error.output}`)
      })
  }
}
