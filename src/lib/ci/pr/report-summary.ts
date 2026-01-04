import {readFileSync} from 'node:fs'
import table, {Header} from 'tty-table'

interface SummaryJson {
  flakyTests: unknown[]
  retryTests: unknown[]
  stats: {
    passed: number
    total: number
  }
  status: string
}

export class ReportSummary {
  private readonly summaryJsonPath: string
  private readonly flakyWarningStatus: boolean
  private _summaryData?: SummaryJson
  private _status?: string
  private _table?: string

  constructor(summaryJsonPath: string, flakyWarningStatus: boolean) {
    this.summaryJsonPath = summaryJsonPath
    this.flakyWarningStatus = flakyWarningStatus
  }

  table() {
    if (this._table) return this._table

    const data = this.summaryData()
    const newTests = data.stats.total - data.stats.passed
    const flaky = data.flakyTests.length
    const retried = data.retryTests.length

    const header: Header[] = [
      {value: 'passed', width: 10},
      {value: 'new', width: 10},
      {value: 'flaky', width: 10},
      {value: 'retried', width: 10},
      {value: 'total', width: 10},
    ].map((h) => ({...h, headerColor: ''}))

    const rows = [[data.stats.passed, newTests, flaky, retried, data.stats.total]]

    const ttyTable = table(header, rows, {
      borderStyle: 'dashed',
      compact: true,
    })

    this._table = `\`\`\`\n${ttyTable.render()}\n\`\`\``
    return this._table
  }

  status() {
    if (this._status) return this._status

    const data = this.summaryData()
    const hasFlaky = data.flakyTests.length > 0
    const hasRetried = data.retryTests.length > 0

    if (data.status === 'passed') {
      this._status = this.flakyWarningStatus && (hasFlaky || hasRetried) ? '❗' : '✅'
    } else {
      this._status = '❌'
    }

    return this._status
  }

  private summaryData() {
    if (this._summaryData) return this._summaryData

    const content = readFileSync(this.summaryJsonPath, 'utf8')
    this._summaryData = JSON.parse(content) as SummaryJson

    return this._summaryData
  }
}
