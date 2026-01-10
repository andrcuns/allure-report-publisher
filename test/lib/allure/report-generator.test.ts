import {expect} from 'chai'
import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {join} from 'node:path'
import {tmpdir} from 'node:os'
import * as sinon from 'sinon'
import esmock from 'esmock'

describe('ReportGenerator', () => {
  let tempDir: string
  let allureConfig: any
  let spawnStub: sinon.SinonStub
  let ReportGenerator: any

  beforeEach(async () => {
    tempDir = join(tmpdir(), `report-gen-test-${Date.now()}`)
    mkdirSync(tempDir, {recursive: true})

    allureConfig = {
      resultsGlob: 'allure-results',
      configPath: () => join(tempDir, 'config.js'),
      outputPath: async () => tempDir,
      historyPath: async () => join(tempDir, 'history'),
      plugins: async () => ['awesome'],
    }

    spawnStub = sinon.stub()

    const module = await esmock('../../../src/lib/allure/report-generator.js', {
      'nano-spawn': {
        default: spawnStub,
      },
    })

    ReportGenerator = module.ReportGenerator
  })

  afterEach(() => {
    sinon.restore()
    rmSync(tempDir, {force: true, recursive: true})
  })

  describe('execute()', () => {
    it('calls spawn with correct allure command arguments', async () => {
      const summaryFile = join(tempDir, 'summary.json')
      writeFileSync(summaryFile, JSON.stringify({stats: {}, status: 'passed'}))

      spawnStub.resolves({
        exitCode: 0,
        output: 'Report successfully generated',
      })

      const generator = new ReportGenerator(allureConfig)
      await generator.execute()

      expect(spawnStub.calledOnce).to.be.true
      expect(spawnStub.firstCall.args[0]).to.equal('allure')
      expect(spawnStub.firstCall.args[1]).to.deep.equal([
        'generate',
        'allure-results',
        '-c',
        join(tempDir, 'config.js'),
        '-o',
        tempDir,
      ])
    })

    it('uses preferLocal true when globalExec is false', async () => {
      writeFileSync(join(tempDir, 'summary.json'), '{}')

      spawnStub.resolves({
        exitCode: 0,
        output: '',
      })

      const generator = new ReportGenerator(allureConfig, false)
      await generator.execute()

      expect(spawnStub.firstCall.args[2]).to.deep.equal({preferLocal: true})
    })

    it('uses preferLocal false when globalExec is true', async () => {
      writeFileSync(join(tempDir, 'summary.json'), '{}')

      spawnStub.resolves({
        exitCode: 0,
        output: '',
      })

      const generator = new ReportGenerator(allureConfig, true)
      await generator.execute()

      expect(spawnStub.firstCall.args[2]).to.deep.equal({preferLocal: false})
    })

    it('throws error when allure command fails', async () => {
      const error = new Error('Allure failed') as any
      error.command = 'allure generate'
      error.exitCode = 1
      error.durationMs = 1000
      error.output = 'Error: Could not generate report'

      spawnStub.rejects(error)

      const generator = new ReportGenerator(allureConfig)

      try {
        await generator.execute()
        expect.fail('Expected error to be thrown')
      } catch (err) {
        expect((err as Error).message).to.include('Allure report generation failed')
        expect((err as Error).message).to.include('Allure failed')
        expect((err as Error).message).to.include('Error: Could not generate report')
      }
    })
  })

  describe('summary()', () => {
    it('throws error when called before execute', () => {
      const generator = new ReportGenerator(allureConfig)

      try {
        generator.summary()
        expect.fail('Expected error to be thrown')
      } catch (error) {
        expect((error as Error).message).to.equal('Report has not been generated yet')
      }
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

      spawnStub.resolves({
        exitCode: 0,
        output: '',
      })

      const generator = new ReportGenerator(allureConfig)
      await generator.execute()

      const summary = generator.summary()

      expect(summary).to.deep.equal(summaryData)
    })

    it('throws error when summary.json not found in generated report', async () => {
      writeFileSync(join(tempDir, 'index.html'), '<html></html>')

      spawnStub.resolves({
        exitCode: 0,
        output: '',
      })

      const generator = new ReportGenerator(allureConfig)
      await generator.execute()

      try {
        generator.summary()
        expect.fail('Expected error to be thrown')
      } catch (error) {
        expect((error as Error).message).to.equal('summary.json file not found in generated report files')
      }
    })
  })
})
