import {getAllureConfig} from '../../lib/allure/config.js'
import {ReportGenerator} from '../../lib/allure/report-generator.js'
import {createReportSection} from '../../lib/ci/update-workflow.js'
import {ciInfo, isCI, isPR} from '../../lib/ci/utils.js'
import {BaseUploadCommand} from '../../lib/commands/upload.js'
import {GitlabArtifactsUploader} from '../../lib/uploader/ci/gitlab-artifacts.js'
import {UpdatePRMode} from '../../types/index.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'

export default class GitlabArtifacts extends BaseUploadCommand {
  static override description = 'Generate report and output GitLab CI artifacts links'
  // Disable strict mode so github actions and gitlab ci templates can use the same command
  static strict = false

  async run() {
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
      const uploader = new GitlabArtifactsUploader({
        reportPath: await allureConfig.outputPath(),
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

      logger.section(`Report URLs`)
      uploader.outputReportUrls()
    } catch (error) {
      this.error(error as Error, {exit: 1})
    }
  }
}
