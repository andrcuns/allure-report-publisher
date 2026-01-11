import {GitlabCiInfo} from '../../../../src/lib/ci/info/gitlab.js'
import {GitlabCiProvider} from '../../../../src/lib/ci/providers/gitlab.js'
import {expect} from '../../../support/setup.js'

describe('GitlabCiInfo', () => {
  let originalEnv: NodeJS.ProcessEnv

  beforeEach(() => {
    originalEnv = {...process.env}
  })

  afterEach(() => {
    process.env = originalEnv
  })

  describe('isPR', () => {
    it('returns true when CI_MERGE_REQUEST_IID is set', () => {
      process.env.CI_MERGE_REQUEST_IID = '42'

      const info = new GitlabCiInfo()

      expect(info.isPR).to.be.true
    })

    it('returns true when ALLURE_PROJECT_PATH and ALLURE_MERGE_REQUEST_IID are set', () => {
      process.env.ALLURE_PROJECT_PATH = 'owner/repo'
      process.env.ALLURE_MERGE_REQUEST_IID = '42'

      const info = new GitlabCiInfo()

      expect(info.isPR).to.be.true
    })

    it('returns false when no MR variables are set', () => {
      delete process.env.CI_MERGE_REQUEST_IID
      delete process.env.ALLURE_MERGE_REQUEST_IID

      const info = new GitlabCiInfo()

      expect(info.isPR).to.be.false
    })
  })

  describe('runId', () => {
    it('returns CI_PIPELINE_ID from environment', () => {
      process.env.CI_PIPELINE_ID = '12345'

      const info = new GitlabCiInfo()

      expect(info.runId).to.equal('12345')
    })

    it('prefers ALLURE_RUN_ID over CI_PIPELINE_ID', () => {
      process.env.ALLURE_RUN_ID = 'custom-run-id'
      process.env.CI_PIPELINE_ID = '12345'

      const info = new GitlabCiInfo()

      expect(info.runId).to.equal('custom-run-id')
    })
  })

  describe('jobId', () => {
    it('returns CI_JOB_ID from environment', () => {
      process.env.CI_JOB_ID = '67890'

      const info = new GitlabCiInfo()

      expect(info.jobId).to.equal('67890')
    })
  })

  describe('projectPath', () => {
    it('returns CI_PROJECT_PATH from environment', () => {
      process.env.CI_PROJECT_PATH = 'group/project'

      const info = new GitlabCiInfo()

      expect(info.projectPath).to.equal('group/project')
    })
  })

  describe('projectName', () => {
    it('returns CI_PROJECT_NAME from environment', () => {
      process.env.CI_PROJECT_NAME = 'my-project'

      const info = new GitlabCiInfo()

      expect(info.projectName).to.equal('my-project')
    })
  })

  describe('projectId', () => {
    it('returns CI_PROJECT_ID from environment', () => {
      process.env.CI_PROJECT_ID = '123'

      const info = new GitlabCiInfo()

      expect(info.projectId).to.equal('123')
    })
  })

  describe('buildDir', () => {
    it('returns CI_PROJECT_DIR from environment', () => {
      process.env.CI_PROJECT_DIR = '/builds/group/project'

      const info = new GitlabCiInfo()

      expect(info.buildDir).to.equal('/builds/group/project')
    })
  })

  describe('branch', () => {
    it('returns CI_COMMIT_REF_NAME from environment', () => {
      process.env.CI_COMMIT_REF_NAME = 'main'

      const info = new GitlabCiInfo()

      expect(info.branch).to.equal('main')
    })

    it('prefers CI_MERGE_REQUEST_SOURCE_BRANCH_NAME over CI_COMMIT_REF_NAME', () => {
      process.env.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME = 'feature-branch'
      process.env.CI_COMMIT_REF_NAME = 'main'

      const info = new GitlabCiInfo()

      expect(info.branch).to.equal('feature-branch')
    })
  })

  describe('serverUrl', () => {
    it('returns CI_SERVER_URL from environment', () => {
      process.env.CI_SERVER_URL = 'https://gitlab.com'

      const info = new GitlabCiInfo()

      expect(info.serverUrl).to.equal('https://gitlab.com')
    })
  })

  describe('buildUrl', () => {
    it('returns CI_PIPELINE_URL from environment', () => {
      process.env.CI_PIPELINE_URL = 'https://gitlab.com/group/project/-/pipelines/12345'

      const info = new GitlabCiInfo()

      expect(info.buildUrl).to.equal('https://gitlab.com/group/project/-/pipelines/12345')
    })
  })

  describe('jobName', () => {
    it('returns CI_JOB_NAME from environment', () => {
      process.env.CI_JOB_NAME = 'test-job'

      const info = new GitlabCiInfo()

      expect(info.jobName).to.equal('test-job')
    })
  })

  describe('buildName', () => {
    it('returns CI_JOB_NAME from environment', () => {
      process.env.CI_JOB_NAME = 'test-job'

      const info = new GitlabCiInfo()

      expect(info.buildName).to.equal('test-job')
    })

    it('prefers ALLURE_JOB_NAME over CI_JOB_NAME', () => {
      process.env.ALLURE_JOB_NAME = 'custom-job'
      process.env.CI_JOB_NAME = 'test-job'

      const info = new GitlabCiInfo()

      expect(info.buildName).to.equal('custom-job')
    })

    it('throws error when build name not available', () => {
      delete process.env.CI_JOB_NAME
      delete process.env.ALLURE_JOB_NAME

      const info = new GitlabCiInfo()

      expect(() => info.buildName).to.throw(Error, 'Build name not found in environment variables')
    })
  })

  describe('pagesDomain', () => {
    it('returns CI_PAGES_DOMAIN from environment', () => {
      process.env.CI_PAGES_DOMAIN = 'gitlab.io'

      const info = new GitlabCiInfo()

      expect(info.pagesDomain).to.equal('gitlab.io')
    })
  })

  describe('pipelineSource', () => {
    it('returns CI_PIPELINE_SOURCE from environment', () => {
      process.env.CI_PIPELINE_SOURCE = 'merge_request_event'

      const info = new GitlabCiInfo()

      expect(info.pipelineSource).to.equal('merge_request_event')
    })
  })

  describe('allureProject', () => {
    it('returns ALLURE_PROJECT_PATH from environment', () => {
      process.env.ALLURE_PROJECT_PATH = 'custom/project'

      const info = new GitlabCiInfo()

      expect(info.allureProject).to.equal('custom/project')
    })
  })

  describe('mrIid', () => {
    it('returns MR IID as number from CI_MERGE_REQUEST_IID', () => {
      process.env.CI_MERGE_REQUEST_IID = '42'

      const info = new GitlabCiInfo()

      expect(info.mrIid).to.equal(42)
    })

    it('prefers ALLURE_MERGE_REQUEST_IID over CI_MERGE_REQUEST_IID', () => {
      process.env.ALLURE_MERGE_REQUEST_IID = '99'
      process.env.CI_MERGE_REQUEST_IID = '42'

      const info = new GitlabCiInfo()

      expect(info.mrIid).to.equal(99)
    })

    it('returns undefined when IID is not a number', () => {
      process.env.CI_MERGE_REQUEST_IID = 'not-a-number'

      const info = new GitlabCiInfo()

      expect(info.mrIid).to.be.undefined
    })

    it('returns undefined when no MR IID is set', () => {
      delete process.env.CI_MERGE_REQUEST_IID
      delete process.env.ALLURE_MERGE_REQUEST_IID

      const info = new GitlabCiInfo()

      expect(info.mrIid).to.be.undefined
    })
  })

  describe('getPrShaUrl()', () => {
    it('returns MR commit URL with short SHA', () => {
      process.env.CI_MERGE_REQUEST_IID = '42'
      process.env.CI_MERGE_REQUEST_SOURCE_SHA = 'abc123def456'
      process.env.CI_PROJECT_PATH = 'group/project'
      process.env.CI_SERVER_URL = 'https://gitlab.com'

      const info = new GitlabCiInfo()

      const url = info.getPrShaUrl()

      expect(url).to.equal(
        '[abc123de](https://gitlab.com/group/project/-/merge_requests/42/diffs?commit_id=abc123def456)',
      )
    })

    it('uses CI_COMMIT_SHA when CI_MERGE_REQUEST_SOURCE_SHA not available', () => {
      process.env.CI_MERGE_REQUEST_IID = '42'
      process.env.CI_COMMIT_SHA = 'def456abc123'
      process.env.CI_PROJECT_PATH = 'group/project'
      process.env.CI_SERVER_URL = 'https://gitlab.com'

      const info = new GitlabCiInfo()

      const url = info.getPrShaUrl()

      expect(url).to.equal(
        '[def456ab](https://gitlab.com/group/project/-/merge_requests/42/diffs?commit_id=def456abc123)',
      )
    })

    it('returns undefined when SHA not available', () => {
      process.env.CI_MERGE_REQUEST_IID = '42'
      process.env.CI_PROJECT_PATH = 'group/project'

      const info = new GitlabCiInfo()

      const url = info.getPrShaUrl()

      expect(url).to.be.undefined
    })

    it('returns undefined when MR IID not available', () => {
      process.env.CI_COMMIT_SHA = 'abc123'
      process.env.CI_PROJECT_PATH = 'group/project'

      const info = new GitlabCiInfo()

      const url = info.getPrShaUrl()

      expect(url).to.be.undefined
    })
  })

  describe('executorJson()', () => {
    it('returns executor information object', () => {
      process.env.CI_SERVER_URL = 'https://gitlab.com'
      process.env.CI_PIPELINE_URL = 'https://gitlab.com/group/project/-/pipelines/12345'
      process.env.CI_PIPELINE_ID = '12345'
      process.env.CI_JOB_NAME = 'test-job'

      const info = new GitlabCiInfo()

      const executor = info.executorJson('https://example.com/report')

      expect(executor).to.deep.equal({
        name: 'GitLab',
        type: 'gitlab',
        reportName: 'AllureReport',
        reportUrl: 'https://example.com/report',
        url: 'https://gitlab.com',
        buildUrl: 'https://gitlab.com/group/project/-/pipelines/12345',
        buildOrder: '12345',
        buildName: 'test-job',
      })
    })
  })

  describe('CiProviderClass', () => {
    it('returns GitlabCiProvider class', () => {
      const info = new GitlabCiInfo()

      expect(info.CiProviderClass).to.equal(GitlabCiProvider)
    })
  })
})
