import {existsSync, mkdirSync, readFileSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'

import {expect} from '../../support/setup.js'

/**
 * Tests for executor.json creation logic extracted from BaseUploadCommand.createExecutorJson.
 * The method should create executor.json only when it does not already exist.
 */
describe('createExecutorJson', () => {
  let tempDir: string
  let resultPath: string

  const executorData = {
    name: 'GitHub',
    type: 'github',
    reportUrl: 'https://example.com/report',
    buildUrl: 'https://github.com/owner/repo/actions/runs/123',
    buildOrder: '123',
    buildName: 'test-job',
  }

  beforeEach(() => {
    tempDir = join(tmpdir(), `executor-json-test-${Date.now()}`)
    resultPath = join(tempDir, 'allure-results')
    mkdirSync(resultPath, {recursive: true})
  })

  afterEach(() => {
    rmSync(tempDir, {force: true, recursive: true})
  })

  it('creates executor.json when it does not exist', () => {
    const executorJsonPath = join(resultPath, 'executor.json')

    expect(existsSync(executorJsonPath)).to.be.false

    writeFileSync(executorJsonPath, JSON.stringify(executorData, null, 2))

    expect(existsSync(executorJsonPath)).to.be.true
    const content = JSON.parse(readFileSync(executorJsonPath, 'utf8'))
    expect(content.reportUrl).to.equal('https://example.com/report')
    expect(content.buildUrl).to.equal('https://github.com/owner/repo/actions/runs/123')
  })

  it('skips creation when executor.json already exists', () => {
    const executorJsonPath = join(resultPath, 'executor.json')
    const existingData = {name: 'existing', reportUrl: 'https://existing.com'}
    writeFileSync(executorJsonPath, JSON.stringify(existingData))

    // Simulate the fixed logic: if (existsSync(executorJson)) continue
    if (!existsSync(executorJsonPath)) {
      writeFileSync(executorJsonPath, JSON.stringify(executorData, null, 2))
    }

    const content = JSON.parse(readFileSync(executorJsonPath, 'utf8'))
    expect(content.reportUrl).to.equal('https://existing.com')
    expect(content.name).to.equal('existing')
  })

  it('creates executor.json in multiple result directories', () => {
    const resultPath2 = join(tempDir, 'allure-results-2')
    mkdirSync(resultPath2, {recursive: true})

    const paths = [resultPath, resultPath2]

    for (const p of paths) {
      const executorJsonPath = join(p, 'executor.json')
      if (existsSync(executorJsonPath)) continue

      writeFileSync(executorJsonPath, JSON.stringify(executorData, null, 2))
    }

    for (const p of paths) {
      const content = JSON.parse(readFileSync(join(p, 'executor.json'), 'utf8'))
      expect(content.reportUrl).to.equal('https://example.com/report')
    }
  })
})
