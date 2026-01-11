import esmock from 'esmock'
import {SubprocessError} from 'nano-spawn'
import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import * as sinon from 'sinon'

import type {ReportGenerator} from '../../../src/lib/allure/report-generator.js'

import {AllureConfig} from '../../../src/lib/allure/config.js'
import {expect} from '../../support/setup.js'

describe('ReportGenerator', () => {
  let tempDir: string
  let allureConfig: AllureConfig
  let spawnStub: sinon.SinonStub
  let Generator: typeof ReportGenerator

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

    Generator = module.ReportGenerator
  })

  afterEach(() => {
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

      const generator = new Generator(allureConfig)
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

      const generator = new Generator(allureConfig, false)
      await generator.execute()

      expect(spawnStub.firstCall.args[2]).to.deep.equal({preferLocal: true})
    })

    it('uses preferLocal false when globalExec is true', async () => {
      writeFileSync(join(tempDir, 'summary.json'), '{}')

      spawnStub.resolves({
        exitCode: 0,
        output: '',
      })

      const generator = new Generator(allureConfig, true)
      await generator.execute()

      expect(spawnStub.firstCall.args[2]).to.deep.equal({preferLocal: false})
    })

    it('throws error when allure command fails', async () => {
      const error = new Error('Allure failed') as SubprocessError
      error.command = 'allure generate'
      error.exitCode = 1
      error.durationMs = 1000
      error.output = 'Error: Could not generate report'

      spawnStub.rejects(error)

      const generator = new Generator(allureConfig)
      const errorMessage = `Allure report generation failed.\nMessage: ${error.message}\nOutput: ${error.output}`

      expect(generator.execute()).to.be.rejectedWith(Error, errorMessage)
    })
  })

  describe('summary()', () => {
    it('throws error when called before execute', () => {
      const generator = new Generator(allureConfig)

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

      spawnStub.resolves({
        exitCode: 0,
        output: '',
      })

      const generator = new Generator(allureConfig)
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

      const generator = new Generator(allureConfig)
      await generator.execute()

      expect(() => generator.summary()).to.throw(Error, 'summary.json file not found in generated report files')
    })
  })
})
