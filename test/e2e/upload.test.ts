import {runCommand} from '@oclif/test'
import type {StartedTestContainer} from 'testcontainers'
import {GenericContainer, Wait} from 'testcontainers'

import {globPaths} from '../../src/utils/glob.js'
import {expect} from '../support/setup.js'

describe('e2e', () => {
  const resultsGlob = process.env.ALLURE_RESULTS_GLOB ?? 'test/fixtures/allure-results'

  let seaweedfsContainer: StartedTestContainer | undefined
  let commandError: Error | undefined
  let originalEnv: NodeJS.ProcessEnv

  before(async () => {
    originalEnv = {...process.env}

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
    process.env.NODE_ENV = 'test' // Set node environment for global config reinitialization to work
  })

  after(async () => {
    if (seaweedfsContainer) await seaweedfsContainer.stop()
    seaweedfsContainer = undefined
    if (originalEnv !== undefined) process.env = originalEnv
  })

  afterEach(function () {
    if (this.currentTest?.state === 'failed') {
      console.log('Command failed:', commandError?.message)
    }
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
