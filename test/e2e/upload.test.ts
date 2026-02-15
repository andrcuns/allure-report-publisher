import {runCommand} from '@oclif/test'
import {mkdirSync} from 'node:fs'
import path from 'node:path'
import {GenericContainer, StartedTestContainer} from 'testcontainers'

import {globPaths} from '../../src/utils/glob.js'
import {expect} from '../support/setup'

describe('e2e', () => {
  const resultsGlob = process.env.ALLURE_RESULTS_GLOB ?? 'test/fixtures/allure-results'

  let minioContainer: StartedTestContainer | undefined
  let commandError: Error | undefined
  let originalEnv: NodeJS.ProcessEnv
  let minioDir: string

  before(async () => {
    originalEnv = {...process.env}
    minioDir = path.resolve(process.cwd(), 'tmp/minio')
    mkdirSync(path.join(minioDir, 'allure-reports'), {recursive: true})

    minioContainer = await new GenericContainer('quay.io/minio/minio:latest')
      .withEnvironment({
        MINIO_ROOT_USER: 'minioadmin',
        MINIO_ROOT_PASSWORD: 'minioadmin',
      })
      .withBindMounts([
        {
          source: minioDir,
          target: '/data',
        },
      ])
      .withExposedPorts(9000)
      .withCommand(['server', '/data'])
      .start()

    const endpoint = `http://${minioContainer.getHost()}:${minioContainer.getMappedPort(9000)}`
    process.env.AWS_ENDPOINT = endpoint
    process.env.AWS_FORCE_PATH_STYLE = 'true'
    process.env.AWS_ACCESS_KEY_ID = 'minioadmin'
    process.env.AWS_SECRET_ACCESS_KEY = 'minioadmin'
    process.env.NODE_ENV = 'test' // Set node environment for global config reinitialization to work
  })

  after(async () => {
    if (minioContainer) await minioContainer.stop()
    minioContainer = undefined
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

    // eslint-disable-next-line mocha/no-skipped-tests
    it.skip('creates executor.json file', async () => {
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
