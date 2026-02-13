import esmock from 'esmock'
import {dirname} from 'node:path'
import * as sinon from 'sinon'

import {GitlabArtifactsUploader} from '../../../../src/lib/uploader/ci/gitlab-artifacts.js'
import {expect} from '../../../support/setup.js'

describe('GitlabArtifactsUploader', () => {
  let originalEnv: NodeJS.ProcessEnv
  let loggerInfoStub: sinon.SinonStub
  let loggerDebugStub: sinon.SinonStub
  let mkdirSyncStub: sinon.SinonStub
  let writeFileSyncStub: sinon.SinonStub
  let pipelinesAllStub: sinon.SinonStub
  let jobsAllStub: sinon.SinonStub
  let downloadArchiveStub: sinon.SinonStub
  let Uploader: typeof GitlabArtifactsUploader

  const historyPath = '/builds/group/project/reports/history/history.json'
  const reportPath = '/builds/group/project/reports/allure'

  beforeEach(async () => {
    originalEnv = {...process.env}
    process.env.CI_COMMIT_REF_NAME = 'main'
    process.env.CI_JOB_NAME = 'test-job'
    process.env.CI_JOB_ID = '101'
    process.env.CI_PAGES_DOMAIN = 'pages.example.com'
    process.env.CI_PIPELINE_SOURCE = 'push'
    process.env.CI_PROJECT_ID = '123'
    process.env.CI_PROJECT_PATH = 'group/subgroup/project'
    process.env.CI_PIPELINE_ID = '200'
    process.env.CI_SERVER_URL = 'https://gitlab.example.com'
    process.env.CI_PROJECT_DIR = '/builds/group/project'

    loggerInfoStub = sinon.stub()
    loggerDebugStub = sinon.stub()
    mkdirSyncStub = sinon.stub()
    writeFileSyncStub = sinon.stub()

    pipelinesAllStub = sinon.stub()
    jobsAllStub = sinon.stub()
    downloadArchiveStub = sinon.stub()

    const gitlabClientStub = {
      JobArtifacts: {
        downloadArchive: downloadArchiveStub,
      },
      Jobs: {
        all: jobsAllStub,
      },
      Pipelines: {
        all: pipelinesAllStub,
      },
    }

    const module = await esmock('../../../../src/lib/uploader/ci/gitlab-artifacts.js', {
      '../../../../src/lib/ci/utils.js': {
        gitlabClient: gitlabClientStub,
      },
      '../../../../src/utils/logger.js': {
        logger: {
          debug: loggerDebugStub,
          info: loggerInfoStub,
        },
      },
      'node:fs': {
        mkdirSync: mkdirSyncStub,
        writeFileSync: writeFileSyncStub,
      },
    })

    Uploader = module.GitlabArtifactsUploader
  })

  afterEach(() => {
    process.env = originalEnv
  })

  describe('reportUrl()', () => {
    it('returns the main artifacts report URL', () => {
      const uploader = new Uploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a', 'plugin-b'],
      })

      const url = uploader.reportUrl()

      expect(url).to.equal('https://group.pages.example.com/-/jobs/101/artifacts/reports/allure/index.html')
    })

    it('uses fallback URL format when server URL is invalid', () => {
      process.env.CI_PROJECT_PATH = 'group/sub/project'
      process.env.CI_SERVER_URL = '::invalid::'
      delete process.env.CI_PAGES_DOMAIN

      const uploader = new Uploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a'],
      })

      const url = uploader.reportUrl()

      expect(url).to.equal('https://group.gitlab.io/-/sub/project/-/jobs/101/artifacts/reports/allure/index.html')
    })
  })

  describe('outputReportUrls()', () => {
    it('logs all report URLs when plugins list has more than one entry', () => {
      const uploader = new Uploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a', 'plugin-b'],
      })

      uploader.outputReportUrls()

      expect(loggerInfoStub.callCount).to.equal(3)
      expect(loggerInfoStub.getCall(0).args[0]).to.equal(
        '- https://group.pages.example.com/-/jobs/101/artifacts/reports/allure/index.html',
      )
      expect(loggerInfoStub.getCall(1).args[0]).to.equal(
        '- https://group.pages.example.com/-/jobs/101/artifacts/reports/allure/plugin-a/index.html',
      )
      expect(loggerInfoStub.getCall(2).args[0]).to.equal(
        '- https://group.pages.example.com/-/jobs/101/artifacts/reports/allure/plugin-b/index.html',
      )
    })
  })

  describe('downloadHistory()', () => {
    it('downloads history artifact from a previous pipeline job', async () => {
      pipelinesAllStub.resolves([{id: 200}, {id: 199}])
      jobsAllStub.onCall(0).resolves([{id: 555, name: 'test-job'}])
      jobsAllStub.onCall(1).resolves([])
      downloadArchiveStub.resolves({
        text: async () => '{"uuid":"test-uuid"}',
      })

      const uploader = new Uploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a'],
      })

      await uploader.downloadHistory()

      expect(mkdirSyncStub.calledOnceWithExactly(dirname(historyPath), {recursive: true})).to.be.true
      expect(
        pipelinesAllStub.calledOnceWithExactly('123', {
          ref: 'main',
          source: 'push',
          perPage: 100,
          maxPages: 1,
        }),
      ).to.be.true
      expect(jobsAllStub.getCall(0).args).to.deep.equal([
        '123',
        {
          pipelineId: 199,
          scope: 'failed',
          includeRetried: false,
          perPage: 100,
        },
      ])
      expect(jobsAllStub.getCall(1).args).to.deep.equal([
        '123',
        {
          pipelineId: 199,
          scope: 'success',
          includeRetried: false,
          perPage: 100,
        },
      ])
      expect(
        downloadArchiveStub.calledOnceWithExactly('123', {
          jobId: 555,
          artifactPath: 'reports/history/history.json',
        }),
      ).to.be.true
      expect(writeFileSyncStub.calledOnceWithExactly(historyPath, '{"uuid":"test-uuid"}')).to.be.true
    })

    it('throws when there are not enough pipelines to resolve a previous job', async () => {
      pipelinesAllStub.resolves([{id: 200}])

      const uploader = new Uploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a'],
      })

      await expect(uploader.downloadHistory()).to.be.rejectedWith(Error, 'Not enough pipelines found')
    })

    it('throws a wrapped error when artifacts download fails', async () => {
      pipelinesAllStub.resolves([{id: 200}, {id: 199}])
      jobsAllStub.onCall(0).resolves([{id: 555, name: 'test-job'}])
      jobsAllStub.onCall(1).resolves([])
      downloadArchiveStub.rejects(new Error('network failure'))

      const uploader = new Uploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a'],
      })

      await expect(uploader.downloadHistory()).to.be.rejectedWith(
        Error,
        "Failed to download history artifact from job ID: '555'. Err: 'network failure'",
      )
    })
  })
})
