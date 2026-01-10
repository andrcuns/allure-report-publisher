/* eslint-disable camelcase */
import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'

import {GithubCiInfo} from '../../../../src/lib/ci/info/github.js'
import {GithubCiProvider} from '../../../../src/lib/ci/providers/github.js'
import {expect} from '../../../support/setup.js'

describe('GithubCiInfo', () => {
  let tempDir: string
  let originalEnv: NodeJS.ProcessEnv

  beforeEach(() => {
    tempDir = join(tmpdir(), `github-ci-test-${Date.now()}`)
    mkdirSync(tempDir, {recursive: true})
    originalEnv = {...process.env}
  })

  afterEach(() => {
    process.env = originalEnv
    rmSync(tempDir, {force: true, recursive: true})
  })

  describe('isPR', () => {
    it('returns true when event name is pull_request', () => {
      process.env.GITHUB_EVENT_NAME = 'pull_request'

      const info = new GithubCiInfo()

      expect(info.isPR).to.be.true
    })

    it('returns false when event name is not pull_request', () => {
      process.env.GITHUB_EVENT_NAME = 'push'

      const info = new GithubCiInfo()

      expect(info.isPR).to.be.false
    })
  })

  describe('runId', () => {
    it('returns GITHUB_RUN_ID from environment', () => {
      process.env.GITHUB_RUN_ID = '12345'

      const info = new GithubCiInfo()

      expect(info.runId).to.equal('12345')
    })

    it('prefers ALLURE_RUN_ID over GITHUB_RUN_ID', () => {
      process.env.ALLURE_RUN_ID = 'custom-run-id'
      process.env.GITHUB_RUN_ID = '12345'

      const info = new GithubCiInfo()

      expect(info.runId).to.equal('custom-run-id')
    })
  })

  describe('serverUrl', () => {
    it('returns GITHUB_SERVER_URL from environment', () => {
      process.env.GITHUB_SERVER_URL = 'https://github.com'

      const info = new GithubCiInfo()

      expect(info.serverUrl).to.equal('https://github.com')
    })
  })

  describe('repository', () => {
    it('returns GITHUB_REPOSITORY from environment', () => {
      process.env.GITHUB_REPOSITORY = 'owner/repo'

      const info = new GithubCiInfo()

      expect(info.repository).to.equal('owner/repo')
    })
  })

  describe('buildName', () => {
    it('returns GITHUB_JOB from environment', () => {
      process.env.GITHUB_JOB = 'test-job'

      const info = new GithubCiInfo()

      expect(info.buildName).to.equal('test-job')
    })

    it('prefers ALLURE_JOB_NAME over GITHUB_JOB', () => {
      process.env.ALLURE_JOB_NAME = 'custom-job'
      process.env.GITHUB_JOB = 'test-job'

      const info = new GithubCiInfo()

      expect(info.buildName).to.equal('custom-job')
    })

    it('throws error when build name not available', () => {
      delete process.env.GITHUB_JOB
      delete process.env.ALLURE_JOB_NAME

      const info = new GithubCiInfo()

      expect(() => info.buildName).to.throw(Error, 'Build name not found in environment variables')
    })
  })

  describe('buildUrl', () => {
    it('constructs build URL from environment variables', () => {
      process.env.GITHUB_SERVER_URL = 'https://github.com'
      process.env.GITHUB_REPOSITORY = 'owner/repo'
      process.env.GITHUB_RUN_ID = '12345'

      const info = new GithubCiInfo()

      expect(info.buildUrl).to.equal('https://github.com/owner/repo/actions/runs/12345')
    })
  })

  describe('prId', () => {
    it('returns PR number from event file', () => {
      const eventPath = join(tempDir, 'event.json')
      const eventData = {
        number: 42,
        pull_request: {
          head: {
            sha: 'abc123',
          },
        },
      }
      writeFileSync(eventPath, JSON.stringify(eventData))
      process.env.GITHUB_EVENT_PATH = eventPath

      const info = new GithubCiInfo()

      expect(info.prId).to.equal(42)
    })

    it('throws error when event path not set', () => {
      delete process.env.GITHUB_EVENT_PATH

      const info = new GithubCiInfo()

      expect(() => info.prId).to.throw(Error, 'GITHUB_EVENT_PATH is not set')
    })
  })

  describe('getPrShaUrl()', () => {
    it('returns PR commit URL with short SHA', () => {
      const eventPath = join(tempDir, 'event.json')
      const eventData = {
        number: 42,
        pull_request: {
          head: {
            sha: 'abc123def456',
          },
        },
      }
      writeFileSync(eventPath, JSON.stringify(eventData))
      process.env.GITHUB_EVENT_PATH = eventPath
      process.env.GITHUB_SERVER_URL = 'https://github.com'
      process.env.GITHUB_REPOSITORY = 'owner/repo'

      const info = new GithubCiInfo()

      const url = info.getPrShaUrl()

      expect(url).to.equal('[abc123de](https://github.com/owner/repo/pull/42/commits/abc123def456)')
    })

    it('returns undefined when PR SHA not available', () => {
      const eventPath = join(tempDir, 'event.json')
      const eventData = {
        number: 42,
      }
      writeFileSync(eventPath, JSON.stringify(eventData))
      process.env.GITHUB_EVENT_PATH = eventPath

      const info = new GithubCiInfo()

      const url = info.getPrShaUrl()

      expect(url).to.be.undefined
    })
  })

  describe('executorJson()', () => {
    it('returns executor information object', () => {
      process.env.GITHUB_SERVER_URL = 'https://github.com'
      process.env.GITHUB_REPOSITORY = 'owner/repo'
      process.env.GITHUB_RUN_ID = '12345'
      process.env.GITHUB_JOB = 'test-job'

      const info = new GithubCiInfo()

      const executor = info.executorJson('https://example.com/report')

      expect(executor).to.deep.equal({
        name: 'GitHub',
        type: 'github',
        reportName: 'AllureReport',
        reportUrl: 'https://example.com/report',
        url: 'https://github.com',
        buildUrl: 'https://github.com/owner/repo/actions/runs/12345',
        buildOrder: '12345',
        buildName: 'test-job',
      })
    })
  })

  describe('CiProviderClass', () => {
    it('returns GithubCiProvider class', () => {
      const info = new GithubCiInfo()

      expect(info.CiProviderClass).to.equal(GithubCiProvider)
    })
  })
})
