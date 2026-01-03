import {runCommand} from '@oclif/test'
import {expect} from 'chai'

describe('upload', () => {
  it('runs upload to s3 bucket', async () => {
    const {stdout} = await runCommand('upload s3 --help')
    expect(stdout).to.contain('Generate and upload allure report to s3 bucket')
  })

  it('runs upload to gcs bucket', async () => {
    const {stdout} = await runCommand('upload gcs --help')
    expect(stdout).to.contain('Generate and upload allure report to gcs bucket')
  })

  it('runs upload to gitlab artifacts', async () => {
    const {stdout} = await runCommand('upload gitlab-artifacts --help')
    expect(stdout).to.contain('Generate report and output GitLab CI artifacts links')
  })
})
