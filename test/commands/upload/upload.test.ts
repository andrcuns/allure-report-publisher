import {runCommand} from '@oclif/test'

import {globalConfig} from '../../../src/utils/global-config.js'
import {expect} from '../../support/setup.js'

describe('upload', () => {
  beforeEach(() => {
    globalConfig.disableOutput = false
  })

  describe('help', () => {
    it('prints s3 upload command help', async () => {
      const {stdout} = await runCommand('upload s3 --help')
      expect(stdout).to.contain('Generate and upload allure report to s3 bucket')
    })

    it('prints gcs upload command help', async () => {
      const {stdout} = await runCommand('upload gcs --help')
      expect(stdout).to.contain('Generate and upload allure report to gcs bucket')
    })

    it('prints gitlab artifacts upload command help', async () => {
      const {stdout} = await runCommand('upload gitlab-artifacts --help')
      expect(stdout).to.contain('Generate report and output GitLab CI artifacts links')
    })
  })

  describe('s3', () => {
    let commandError: Error | undefined
    let output: string

    afterEach(function () {
      if (this.currentTest?.state === 'failed') {
        console.log('Command failed:', commandError?.message)
        console.log(`Test output:\n${output}`)
      }
    })

    it('runs s3 upload command', async function () {
      if (process.env.E2E_TEST !== 'true') return this.skip()

      const {AWS_ENDPOINT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY} = process.env
      if (!AWS_ENDPOINT || !AWS_ACCESS_KEY_ID || !AWS_SECRET_ACCESS_KEY) throw new Error('Missing aws env variables')

      const prefix = `allure-report-publisher/${process.env.GITHUB_REF ?? 'local'}`
      const args = [
        '--config=allurerc.mjs',
        '--bucket=allure-reports',
        `--prefix=${prefix}`,
        '--update-pr=comment',
        '--ci-report-title=Unit Test Report',
        '--report-name=Unit Test Report',
        '--add-summary',
        '--collapse-summary',
        '--copy-latest',
        '--debug',
      ]
      const {stdout, error} = await runCommand(`upload s3 ${args.join(' ')}`)
      commandError = error
      output = stdout

      expect(error).to.be.undefined
      expect(stdout).to.match(new RegExp(`${AWS_ENDPOINT}/allure-reports/${prefix}/[\\w/]+/index.html`))
    })
  })
})
