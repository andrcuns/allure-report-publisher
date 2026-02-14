import {runCommand} from '@oclif/test'

import {globalConfig} from '../../src/utils/global-config'
import {expect} from '../support/setup'

describe('e2e', () => {
  let commandError: Error | undefined

  beforeEach(function () {
    if (process.env.E2E_TEST !== 'true') return this.skip()
  })

  afterEach(function () {
    globalConfig.reset()

    if (this.currentTest?.state === 'failed') {
      console.log('Command failed:', commandError?.message)
    }
  })

  describe('s3', () => {
    it('runs s3 upload command', async () => {
      const {AWS_ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY} = process.env
      if (!AWS_ENDPOINT || !AWS_ACCESS_KEY_ID || !AWS_SECRET_ACCESS_KEY) throw new Error('Missing aws env variables')

      const prefix = `allure-report-publisher/${process.env.GITHUB_REF ?? 'local'}`
      const {stdout, error} = await runCommand([
        'upload',
        's3',
        `--results-glob=${process.env.ALLURE_RESULTS_GLOB ?? './**/allure-results'}`,
        '--config=allurerc.mjs',
        '--bucket=allure-reports',
        `--prefix=${prefix}`,
        '--update-pr=comment',
        '--ci-report-title=unit-test-report',
        '--report-name=unit-test-report',
        '--add-summary',
        '--collapse-summary',
        '--copy-latest',
        '--debug',
      ])
      commandError = error

      expect(error?.message).to.be.undefined
      expect(stdout).to.match(new RegExp(`${AWS_ENDPOINT}/allure-reports/${prefix}/[\\w/]+/index.html`))
    })
  })
})
