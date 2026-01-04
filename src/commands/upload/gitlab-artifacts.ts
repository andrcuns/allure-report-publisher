import {getAllureConfig} from '../../lib/allure/config.js'
import {ReportGenerator} from '../../lib/allure/report-generator.js'
import {BaseUploadCommand} from '../../lib/commands/upload.js'
import {GitlabArtifactsUploader} from '../../lib/uploader/ci/gitlab-artifacts.js'
import {isCi} from '../../utils/ci.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'

export default class GitlabArtifacts extends BaseUploadCommand {
  static override description = 'Generate report and output GitLab CI artifacts links'

  async run() {
    const flags = await this.initConfig()

    try {
      await this.validateInputs(flags)

      logger.section('Generating allure report')
      const allureConfig = getAllureConfig({
        configPath: flags.config,
        reportName: flags['report-name'],
        resultsGlob: flags['results-glob'],
      })
      const uploader = new GitlabArtifactsUploader({
        reportPath: await allureConfig.outputPath(),
        historyPath: await allureConfig.historyPath(),
        plugins: await allureConfig.plugins(),
      })

      await spin(uploader.downloadHistory(), 'downloading previous run history', {ignoreError: true})

      // legacy executor.json for allure2 plugin
      if (isCi && (await allureConfig.plugins()).includes('allure2')) {
        await spin(this.createExecutorJson(uploader.reportUrl()), 'creating executor.json files')
      }

      await new ReportGenerator(allureConfig).execute()

      logger.section(`Report URLs`)
      await uploader.outputReportUrls()

      // TODO: Update PR if requested
      if (flags['update-pr']) {
        logger.section('Updating PR/MR')
        logger.info('PR update not yet implemented')
      }
    } catch (error) {
      this.error(error as Error, {exit: 1})
    }
  }
}
