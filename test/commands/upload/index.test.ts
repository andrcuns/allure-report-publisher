import {runCommand} from '@oclif/test'
import {expect} from 'chai'

describe('upload', () => {
  it('runs upload', async () => {
    const {stdout} = await runCommand('upload --help')
    expect(stdout).to.contain(
      'allure-report-publisher upload s3 --results-glob="path/to/allure-results" --bucket=my-bucket',
    )
  })
})
