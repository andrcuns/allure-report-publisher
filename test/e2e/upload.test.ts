import {cpSync, mkdtempSync, rmSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import type {StartedTestContainer} from 'testcontainers'
import {GenericContainer, Wait} from 'testcontainers'
import {afterAll, beforeAll, beforeEach, describe, expect, it, onTestFailed} from 'vitest'

import {getAllureResultsPaths, globPaths} from '../../src/utils/glob.js'
import {runCommand} from '../support/command.js'
import {cleanupE2eResources} from '../support/e2e-resources.js'

describe('e2e', () => {
  const sourceResultsGlob = process.env.ALLURE_RESULTS_GLOB ?? 'test/fixtures/allure-results'

  let resultsGlob: string
  let fixtureRoot: string | undefined
  let seaweedfsContainer: StartedTestContainer | undefined
  let commandError: Error | undefined
  let originalEnv: NodeJS.ProcessEnv | undefined

  beforeAll(async () => {
    originalEnv = {...process.env}

    process.env.GITHUB_WORKFLOW ??= 'vitest-e2e'
    process.env.GITHUB_JOB ??= 'e2e'
    process.env.GITHUB_RUN_ID ??= '1'
    process.env.GITHUB_SERVER_URL ??= 'https://github.com'
    process.env.GITHUB_REPOSITORY ??= 'andrcuns/allure-report-publisher'
    process.env.GITHUB_EVENT_NAME = 'push'
    process.env.NODE_ENV = 'test'

    fixtureRoot = mkdtempSync(join(tmpdir(), 'publisher-vitest-e2e-'))
    const sourcePaths = await getAllureResultsPaths(sourceResultsGlob)
    if (!sourcePaths?.length) throw new Error(`No E2E inputs found for ${sourceResultsGlob}`)
    for (const [index, source] of sourcePaths.entries()) {
      const destination = join(fixtureRoot, 'results', String(index))
      cpSync(source, destination, {recursive: true, dereference: true})
      rmSync(join(destination, 'executor.json'), {force: true})
    }
    resultsGlob = join(fixtureRoot, 'results', '*')

    seaweedfsContainer = await new GenericContainer('chrislusf/seaweedfs:4.47')
      .withEnvironment({
        AWS_ACCESS_KEY_ID: 'seaweedfs',
        AWS_SECRET_ACCESS_KEY: 'seaweedfs',
        S3_BUCKET: 'allure-reports',
      })
      .withExposedPorts(8333)
      .withWaitStrategy(Wait.forLogMessage(/created bucket allure-reports/))
      .start()

    const endpoint = `http://${seaweedfsContainer.getHost()}:${seaweedfsContainer.getMappedPort(8333)}`
    process.env.AWS_ENDPOINT = endpoint
    process.env.AWS_FORCE_PATH_STYLE = 'true'
    process.env.AWS_ACCESS_KEY_ID = 'seaweedfs'
    process.env.AWS_SECRET_ACCESS_KEY = 'seaweedfs'
  })

  afterAll(async () => {
    try {
      await cleanupE2eResources({container: seaweedfsContainer, fixtureRoot, originalEnv})
    } finally {
      seaweedfsContainer = undefined
      fixtureRoot = undefined
    }
  })

  beforeEach(() => {
    commandError = undefined
    onTestFailed(() => {
      process.stderr.write(`Command failed: ${commandError?.message ?? 'no command error recorded'}\n`)
    })
  })

  describe('s3', () => {
    it('runs s3 upload command', async () => {
      const prefix = `allure-report-publisher/${process.env.GITHUB_REF ?? 'local'}`
      const {stdout, error} = await runCommand([
        'upload',
        's3',
        `--results-glob=${resultsGlob}`,
        '--config=allurerc.mjs',
        '--bucket=allure-reports',
        `--prefix=${prefix}`,
        '--copy-latest',
        '--debug',
      ])
      commandError = error

      expect(error?.message).to.be.undefined
      expect(stdout).to.match(new RegExp(`${process.env.AWS_ENDPOINT}/allure-reports/${prefix}/[\\w/]+/index.html`))
    })

    it('creates executor.json file', async () => {
      expect(await globPaths(`${resultsGlob}/executor.json`, {nodir: true})).to.be.empty

      const {error} = await runCommand([
        'upload',
        's3',
        `--results-glob=${resultsGlob}`,
        '--config=test/fixtures/configs/allure2.json',
        '--bucket=allure-reports',
      ])
      commandError = error

      expect(error?.message).to.be.undefined
      expect(await globPaths(`${resultsGlob}/executor.json`, {nodir: true})).to.not.be.empty
    })
  })
})
