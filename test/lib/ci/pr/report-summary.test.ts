import {expect} from 'chai'
import dedent from 'dedent'
import {readFileSync} from 'node:fs'
import {dirname, resolve} from 'node:path'
import {fileURLToPath} from 'node:url'

import {ReportSummary} from '../../../../src/lib/ci/pr/report-summary.js'
import {SummaryJson} from '../../../../src/types/index.js'

const summaryData = (file: string) => {
  const fixturesPath = resolve(dirname(fileURLToPath(import.meta.url)), '../../../fixtures')
  return JSON.parse(readFileSync(resolve(fixturesPath, file), 'utf8')) as SummaryJson
}

describe('ReportSummary', () => {
  describe('table()', () => {
    it('generates table with test statistics', () => {
      const summary = new ReportSummary(summaryData('summary-passed.json'), false)
      const table = summary.table()
      const expected = dedent`
      \`\`\`console
        +----------+----------+----------+----------+----------+----------+
        |  passed  |  failed  |  flaky   | retried  | skipped  |  total   |
        +----------+----------+----------+----------+----------+----------+
        |    45    |    0     |    0     |    0     |    5     |    50    |
        +----------+----------+----------+----------+----------+----------+
      \`\`\``

      expect(table).to.equal(expected)
    })

    it('includes flaky and retried test counts', () => {
      const summary = new ReportSummary(summaryData('summary-flaky.json'), false)
      const table = summary.table()
      const expected = dedent`
      \`\`\`console
        +----------+----------+----------+----------+----------+----------+
        |  passed  |  failed  |  flaky   | retried  | skipped  |  total   |
        +----------+----------+----------+----------+----------+----------+
        |    48    |    0     |    1     |    1     |    0     |    50    |
        +----------+----------+----------+----------+----------+----------+
      \`\`\``

      expect(table).to.equal(expected)
    })
  })

  describe('status()', () => {
    it('returns checkmark for passed tests', () => {
      const summary = new ReportSummary(summaryData('summary-passed.json'), false)

      expect(summary.status()).to.equal('✅')
    })

    it('returns cross mark for failed tests', () => {
      const summary = new ReportSummary(summaryData('summary-failed.json'), false)

      expect(summary.status()).to.equal('❌')
    })

    it('returns warning when flaky warning is enabled and tests are flaky', () => {
      const summary = new ReportSummary(summaryData('summary-flaky.json'), true)

      expect(summary.status()).to.equal('❗')
    })

    it('returns checkmark when flaky warning is disabled and tests are flaky', () => {
      const summary = new ReportSummary(summaryData('summary-flaky.json'), false)

      expect(summary.status()).to.equal('✅')
    })
  })
})
