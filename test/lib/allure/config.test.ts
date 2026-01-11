import dedent from 'dedent'
import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'

import {getAllureConfig} from '../../../src/lib/allure/config.js'
import {expect} from '../../support/setup.js'

describe('getAllureConfig', () => {
  let tempDir: string

  beforeEach(() => {
    tempDir = join(tmpdir(), `config-test-${Date.now()}`)
    mkdirSync(tempDir, {recursive: true})
  })

  afterEach(() => {
    rmSync(tempDir, {force: true, recursive: true})
  })

  describe('DefaultConfig', () => {
    it('returns default config when no custom config path provided', async () => {
      const config = getAllureConfig({resultsGlob: 'allure-results'})

      expect(config.resultsGlob).to.equal('allure-results')
      expect(await config.plugins()).to.deep.equal(['awesome'])
    })

    it('returns history path from default config', async () => {
      const config = getAllureConfig({resultsGlob: 'allure-results'})

      const historyPath = await config.historyPath()

      expect(historyPath).to.include('history.jsonl')
    })

    it('returns output path from default config', async () => {
      const config = getAllureConfig({resultsGlob: 'allure-results'})

      const outputPath = await config.outputPath()

      expect(outputPath).to.include('allure-report')
    })

    it('uses provided output path', async () => {
      const customOutput = join(tempDir, 'custom-output')
      const config = getAllureConfig({
        output: customOutput,
        resultsGlob: 'allure-results',
      })

      const outputPath = await config.outputPath()

      expect(outputPath).to.equal(customOutput)
    })

    it('uses provided report name', async () => {
      const config = getAllureConfig({
        reportName: 'My Custom Report',
        resultsGlob: 'allure-results',
      })

      const configPath = config.configPath()

      expect(configPath).to.include('allurerc.json')
    })

    it('uses default results glob pattern when not provided', () => {
      const config = getAllureConfig({})

      expect(config.resultsGlob).to.equal('./**/allure-results')
    })
  })

  describe('CustomConfig', () => {
    it('loads config from JSON file', async () => {
      const configPath = join(tempDir, 'allure.config.json')
      const configData = {
        output: join(tempDir, 'report'),
        historyPath: join(tempDir, 'history.jsonl'),
      }
      writeFileSync(configPath, JSON.stringify(configData))

      const config = getAllureConfig({configPath, resultsGlob: 'results'})

      expect(await config.outputPath()).to.equal(configData.output)
      expect(await config.historyPath()).to.equal(configData.historyPath)
    })

    it('loads config from YAML file', async () => {
      const configPath = join(tempDir, 'allure.config.yaml')
      const yamlContent = dedent`
        output: ${join(tempDir, 'report')}
        historyPath: ${join(tempDir, 'history.jsonl')}
      `
      writeFileSync(configPath, yamlContent)

      const config = getAllureConfig({configPath, resultsGlob: 'results'})

      expect(await config.outputPath()).to.equal(join(tempDir, 'report'))
      expect(await config.historyPath()).to.equal(join(tempDir, 'history.jsonl'))
    })

    it('loads config from JS file with default export', async () => {
      const configPath = join(tempDir, 'allure.config.js')
      const jsContent = dedent`
        export default {
        output: '${join(tempDir, 'report')}',
        historyPath: '${join(tempDir, 'history.jsonl')}'
      };`
      writeFileSync(configPath, jsContent)

      const config = getAllureConfig({configPath, resultsGlob: 'results'})

      expect(await config.outputPath()).to.equal(join(tempDir, 'report'))
      expect(await config.historyPath()).to.equal(join(tempDir, 'history.jsonl'))
    })

    it('throws error when JS config has no default export', async () => {
      const configPath = join(tempDir, 'allure.config.js')
      writeFileSync(configPath, 'export const config = {};')

      const config = getAllureConfig({configPath, resultsGlob: 'results'})

      await expect(config.outputPath()).to.be.rejectedWith(Error, 'No default export found')
    })

    it('throws error when history path is not defined', async () => {
      const configPath = join(tempDir, 'allure.config.json')
      writeFileSync(configPath, JSON.stringify({output: '/output'}))

      const config = getAllureConfig({configPath, resultsGlob: 'results'})

      await expect(config.historyPath()).to.be.rejectedWith(Error, 'History path is not defined in the allure config')
    })

    it('returns enabled plugins from custom config', async () => {
      const configPath = join(tempDir, 'allure.config.json')
      const configData = {
        output: '/output',
        plugins: {
          awesome: {enabled: true},
          classic: {enabled: false},
          dashboard: {enabled: true},
        },
      }
      writeFileSync(configPath, JSON.stringify(configData))

      const config = getAllureConfig({configPath, resultsGlob: 'results'})

      const plugins = await config.plugins()

      expect(plugins).to.include('awesome')
      expect(plugins).to.include('dashboard')
      expect(plugins).to.not.include('classic')
    })

    it('includes plugins with enabled undefined as true', async () => {
      const configPath = join(tempDir, 'allure.config.json')
      const configData = {
        output: '/output',
        plugins: {
          awesome: {},
          classic: {enabled: true},
        },
      }
      writeFileSync(configPath, JSON.stringify(configData))

      const config = getAllureConfig({configPath, resultsGlob: 'results'})

      const plugins = await config.plugins()

      expect(plugins).to.include('awesome')
      expect(plugins).to.include('classic')
    })

    it('uses provided resultsGlob', () => {
      const configPath = join(tempDir, 'allure.config.json')
      writeFileSync(configPath, JSON.stringify({output: '/output'}))

      const config = getAllureConfig({
        configPath,
        resultsGlob: 'custom-results/**/*',
      })

      expect(config.resultsGlob).to.equal('custom-results/**/*')
    })

    it('returns config path', () => {
      const configPath = join(tempDir, 'allure.config.json')
      writeFileSync(configPath, JSON.stringify({output: '/output'}))

      const config = getAllureConfig({configPath, resultsGlob: 'results'})

      expect(config.configPath()).to.equal(configPath)
    })
  })
})
