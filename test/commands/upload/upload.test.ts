import {describe, expect, it} from 'vitest'

import {runCommand} from '../../support/command.js'

describe('upload', () => {
  describe('help', () => {
    it('prints s3 upload command help', async () => {
      const {stdout, error} = await runCommand(['upload', 's3', '--help'])
      expect(error).toBeUndefined()
      expect(stdout).to.contain('Generate and upload allure report to s3 bucket')
    })

    it('prints gcs upload command help', async () => {
      const {stdout, error} = await runCommand(['upload', 'gcs', '--help'])
      expect(error).toBeUndefined()
      expect(stdout).to.contain('Generate and upload allure report to gcs bucket')
    })

    it('prints gitlab artifacts upload command help', async () => {
      const {stdout, error} = await runCommand(['upload', 'gitlab-artifacts', '--help'])
      expect(error).toBeUndefined()
      expect(stdout).to.contain('Generate report and output GitLab CI artifacts links')
    })
  })
})
