import type {SubprocessError} from 'nano-spawn'
import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest'

import type {AllureConfig} from '../../../src/lib/allure/config.js'
import {ReportGenerator} from '../../../src/lib/allure/report-generator.js'

const {spawnStub} = vi.hoisted(() => ({
  spawnStub: vi.fn<(command: string, args: string[], options: {preferLocal: boolean}) => Promise<unknown>>(),
}))

vi.mock('nano-spawn', () => ({default: spawnStub}))

describe('ReportGenerator', () => {
  const historyBaseUrl = 'https://reports.example.com/project'
  let tempDir: string
  let allureConfig: AllureConfig

  beforeEach(() => {
    spawnStub.mockReset()
    tempDir = join(tmpdir(), `report-gen-test-${Date.now()}`)
    mkdirSync(tempDir, {recursive: true})

    allureConfig = {
      resultsGlob: 'allure-results',
      configPath: () => join(tempDir, 'config.js'),
      outputPath: async () => tempDir,
      historyPath: async () => join(tempDir, 'history'),
      plugins: async () => ['awesome'],
    }
  })

  afterEach(() => {
    rmSync(tempDir, {force: true, recursive: true})
  })

  describe('execute()', () => {
    it('calls spawn with correct allure command arguments including the history base URL', async () => {
      const summaryFile = join(tempDir, 'summary.json')
      writeFileSync(summaryFile, JSON.stringify({stats: {}, status: 'passed'}))

      spawnStub.mockResolvedValue({
        exitCode: 0,
        output: 'Report successfully generated',
      })

      const generator = new ReportGenerator(allureConfig)
      await generator.execute(historyBaseUrl)

      expect(spawnStub).toHaveBeenCalledTimes(1)
      expect(spawnStub.mock.calls[0][0]).to.equal('allure')
      expect(spawnStub.mock.calls[0][1]).to.deep.equal([
        'generate',
        'allure-results',
        '-c',
        join(tempDir, 'config.js'),
        '-o',
        tempDir,
        '--history-base-url',
        historyBaseUrl,
      ])
    })

    it('uses preferLocal true when globalExec is false', async () => {
      writeFileSync(join(tempDir, 'summary.json'), '{}')

      spawnStub.mockResolvedValue({
        exitCode: 0,
        output: '',
      })

      const generator = new ReportGenerator(allureConfig, false)
      await generator.execute(historyBaseUrl)

      expect(spawnStub.mock.calls[0][2]).to.deep.equal({preferLocal: true})
    })

    it('uses preferLocal false when globalExec is true', async () => {
      writeFileSync(join(tempDir, 'summary.json'), '{}')

      spawnStub.mockResolvedValue({
        exitCode: 0,
        output: '',
      })

      const generator = new ReportGenerator(allureConfig, true)
      await generator.execute(historyBaseUrl)

      expect(spawnStub.mock.calls[0][2]).to.deep.equal({preferLocal: false})
    })

    it('throws error when allure command fails', async () => {
      const error = new Error('Allure failed') as SubprocessError
      error.command = 'allure generate'
      error.exitCode = 1
      error.durationMs = 1000
      error.output = 'Error: Could not generate report'

      spawnStub.mockRejectedValue(error)

      const generator = new ReportGenerator(allureConfig)
      const errorMessage = `Allure report generation failed.\nMessage: ${error.message}\nOutput: ${error.output}`

      const result = generator.execute(historyBaseUrl)
      await expect(result).rejects.toBeInstanceOf(Error)
      await expect(result).rejects.toThrow(errorMessage)
    })
  })

  describe('summary()', () => {
    it('throws error when called before execute', () => {
      const generator = new ReportGenerator(allureConfig)

      expect(() => generator.summary()).to.throw(Error, 'Report has not been generated yet')
    })

    it('returns parsed summary data from generated report', async () => {
      const summaryData = {
        stats: {
          total: 100,
          passed: 95,
          failed: 5,
        },
        status: 'failed',
      }

      const summaryFile = join(tempDir, 'summary.json')
      writeFileSync(summaryFile, JSON.stringify(summaryData))

      spawnStub.mockResolvedValue({
        exitCode: 0,
        output: '',
      })

      const generator = new ReportGenerator(allureConfig)
      await generator.execute(historyBaseUrl)

      const summary = generator.summary()

      expect(summary).to.deep.equal(summaryData)
    })

    it('throws error when summary.json not found in generated report', async () => {
      writeFileSync(join(tempDir, 'index.html'), '<html></html>')

      spawnStub.mockResolvedValue({
        exitCode: 0,
        output: '',
      })

      const generator = new ReportGenerator(allureConfig)
      await generator.execute(historyBaseUrl)

      expect(() => generator.summary()).to.throw(Error, 'summary.json file not found in generated report files')
    })
  })
})
