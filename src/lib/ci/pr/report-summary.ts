import table, {Header} from 'tty-table'

import {SummaryJson} from '../../../types/index.js'

type SummaryStats = {
  passed: number
  failed: number
  flaky: number
  retried: number
  skipped: number
  total: number
}

export class ReportSummary {
  private readonly flakyWarningStatus: boolean
  private readonly summaryData: SummaryJson
  private _testStats?: SummaryStats
  private _status?: string
  private _table?: string

  constructor(summaryData: SummaryJson, flakyWarningStatus: boolean) {
    this.summaryData = summaryData
    this.flakyWarningStatus = flakyWarningStatus
  }

  table() {
    if (this._table) return this._table

    const stats = this.testStats()
    const header: Header[] = Object.keys(stats).map((key) => ({value: key, width: 10, headerColor: ''}))

    const ttyTable = table(header, [Object.values(stats)], {
      borderStyle: 'dashed',
      compact: true,
    })

    this._table = `\`\`\`\n${ttyTable.render()}\n\`\`\``
    return this._table
  }

  status() {
    if (this._status) return this._status

    const data = this.summaryData
    const stats = this.testStats()
    const hasFlaky = stats.flaky > 0
    const hasRetried = stats.retried > 0

    if (data.status === 'passed') {
      this._status = this.flakyWarningStatus && (hasFlaky || hasRetried) ? '❗' : '✅'
    } else {
      this._status = '❌'
    }

    return this._status
  }

  private testStats(): SummaryStats {
    if (this._testStats) return this._testStats

    const data = this.summaryData
    this._testStats = {
      passed: data.stats.passed ?? 0,
      failed: (data.stats.failed ?? 0) + (data.stats.broken ?? 0),
      flaky: data.stats.flaky ?? 0,
      retried: data.stats.retries ?? 0,
      skipped: data.stats.skipped ?? 0,
      total: data.stats.total ?? 0,
    }
    return this._testStats
  }
}
