import {expect} from 'chai'
import {dirname, resolve} from 'node:path'
import {fileURLToPath} from 'node:url'

import {ReportSummary} from '../../../../src/lib/ci/pr/report-summary.js'

describe('ReportSummary', () => {
  const fixturesPath = resolve(dirname(fileURLToPath(import.meta.url)), '../../../fixtures')

  describe('table()', () => {
    it('generates table with test statistics', () => {
      const summaryPath = resolve(fixturesPath, 'summary-passed.json')
      const summary = new ReportSummary(summaryPath, false)

      const table = summary.table()

      const expected = `\`\`\`

  +----------+----------+----------+----------+----------+
  |  passed  |   new    |  flaky   | retried  |  total   |
  +----------+----------+----------+----------+----------+
  |    45    |    5     |    0     |    0     |    50    |
  +----------+----------+----------+----------+----------+
\`\`\``

      expect(table).to.equal(expected)
    })

    it('includes flaky and retried test counts', () => {
      const summaryPath = resolve(fixturesPath, 'summary-flaky.json')
      const summary = new ReportSummary(summaryPath, false)

      const table = summary.table()

      const expected = `\`\`\`

  +----------+----------+----------+----------+----------+
  |  passed  |   new    |  flaky   | retried  |  total   |
  +----------+----------+----------+----------+----------+
  |    48    |    2     |    2     |    1     |    50    |
  +----------+----------+----------+----------+----------+
\`\`\``

      expect(table).to.equal(expected)
    })

    it('caches table result', () => {
      const summaryPath = resolve(fixturesPath, 'summary-passed.json')
      const summary = new ReportSummary(summaryPath, false)

      const table1 = summary.table()
      const table2 = summary.table()

      expect(table1).to.equal(table2)
      expect(table1).to.equal(summary.table())
    })
  })

  describe('status()', () => {
    it('returns checkmark for passed tests', () => {
      const summaryPath = resolve(fixturesPath, 'summary-passed.json')
      const summary = new ReportSummary(summaryPath, false)

      expect(summary.status()).to.equal('✅')
    })

    it('returns cross mark for failed tests', () => {
      const summaryPath = resolve(fixturesPath, 'summary-failed.json')
      const summary = new ReportSummary(summaryPath, false)

      expect(summary.status()).to.equal('❌')
    })

    it('returns warning when flaky warning is enabled and tests are flaky', () => {
      const summaryPath = resolve(fixturesPath, 'summary-flaky.json')
      const summary = new ReportSummary(summaryPath, true)

      expect(summary.status()).to.equal('❗')
    })

    it('returns checkmark when flaky warning is disabled and tests are flaky', () => {
      const summaryPath = resolve(fixturesPath, 'summary-flaky.json')
      const summary = new ReportSummary(summaryPath, false)

      expect(summary.status()).to.equal('✅')
    })
  })
})
