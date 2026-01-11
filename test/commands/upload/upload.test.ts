import {runCommand} from '@oclif/test'

import {expect} from '../../support/setup.js'

describe('upload', () => {
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
})
