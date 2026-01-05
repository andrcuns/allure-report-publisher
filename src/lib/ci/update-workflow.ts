import {SummaryJson, UpdatePRMode} from '../../types/index.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'
import {GitlabCiInfo} from './info/gitlab.js'
import {ReportSummary} from './pr/report-summary.js'
import {UrlSectionBuilder} from './pr/url-section-builder.js'
import {ciInfo} from './utils.js'

export async function createReportSection(opts: {
  reportUrl: string
  summary: SummaryJson
  updateMode: UpdatePRMode
  addSummary: boolean
  ciReportTitle: string
  collapseSummary: boolean
  flakyWarningStatus: boolean
  ignoreError?: boolean
}) {
  const runUpdateWorkflow = async () => {
    if (!ciInfo) throw new Error('Failed to detect CI environment')

    const term = ciInfo instanceof GitlabCiInfo ? 'MR' : 'PR'
    logger.section(`Updating ${term}`)
    const urlSectionBuilder = new UrlSectionBuilder({
      reportUrl: opts.reportUrl,
      buildName: ciInfo.buildName,
      shaUrl: ciInfo.getPrShaUrl(),
      summary: new ReportSummary(opts.summary, opts.flakyWarningStatus),
      shouldAddSummaryTable: opts.addSummary,
      shouldCollapseSummary: opts.collapseSummary,
      reportTitle: opts.ciReportTitle,
    })
    const provider = new ciInfo.CiProviderClass(urlSectionBuilder, opts.updateMode)
    await provider.addReportSection()
  }

  await spin(runUpdateWorkflow(), `adding report section to ${opts.updateMode}`, {
    ignoreError: opts.ignoreError || false,
  })
}
