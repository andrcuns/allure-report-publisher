import type * as nodeFs from 'node:fs'
import {dirname} from 'node:path'
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest'

import {GitlabArtifactsUploader} from '../../../../src/lib/uploader/ci/gitlab-artifacts.js'

const mocks = vi.hoisted(() => ({
  info: vi.fn<(message: string) => void>(),
  debug: vi.fn<(message: string) => void>(),
  mkdirSync: vi.fn<(...args: unknown[]) => void>(),
  writeFileSync: vi.fn<(...args: unknown[]) => void>(),
  pipelines: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
  jobs: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
  download: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
}))

vi.mock('../../../../src/lib/ci/utils.js', () => ({
  gitlabClient: {
    Pipelines: {all: mocks.pipelines},
    Jobs: {all: mocks.jobs},
    JobArtifacts: {downloadArchive: mocks.download},
  },
}))

vi.mock('node:fs', async (importOriginal) => ({
  ...(await importOriginal<typeof nodeFs>()),
  mkdirSync: mocks.mkdirSync,
  writeFileSync: mocks.writeFileSync,
}))

vi.mock('../../../../src/utils/logger.js', () => ({
  logger: {info: mocks.info, debug: mocks.debug},
}))

describe('GitlabArtifactsUploader', () => {
  let originalEnv: NodeJS.ProcessEnv

  const historyPath = '/builds/group/project/reports/history/history.json'
  const reportPath = '/builds/group/project/reports/allure'

  beforeEach(() => {
    vi.resetAllMocks()
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
  })

  afterEach(() => {
    process.env = originalEnv
  })

  describe('reportUrl()', () => {
    it('returns the main artifacts report URL', () => {
      const uploader = new GitlabArtifactsUploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a', 'plugin-b'],
      })

      const url = uploader.reportUrl()

      expect(url).to.equal(
        'https://group.pages.example.com/-/subgroup/project/-/jobs/101/artifacts/reports/allure/index.html',
      )
    })

    it('uses fallback URL format when server URL is invalid', () => {
      process.env.CI_PROJECT_PATH = 'group/sub/project'
      process.env.CI_SERVER_URL = '::invalid::'
      delete process.env.CI_PAGES_DOMAIN

      const uploader = new GitlabArtifactsUploader({
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
      const uploader = new GitlabArtifactsUploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a', 'plugin-b'],
      })

      uploader.outputReportUrls()

      expect(mocks.info).toHaveBeenCalledTimes(3)
      expect(mocks.info.mock.calls[0][0]).to.equal(
        '- https://group.pages.example.com/-/subgroup/project/-/jobs/101/artifacts/reports/allure/index.html',
      )
      expect(mocks.info.mock.calls[1][0]).to.equal(
        '- https://group.pages.example.com/-/subgroup/project/-/jobs/101/artifacts/reports/allure/plugin-a/index.html',
      )
      expect(mocks.info.mock.calls[2][0]).to.equal(
        '- https://group.pages.example.com/-/subgroup/project/-/jobs/101/artifacts/reports/allure/plugin-b/index.html',
      )
    })
  })

  describe('downloadHistory()', () => {
    it('downloads history artifact from a previous pipeline job', async () => {
      mocks.pipelines.mockResolvedValue([{id: 200}, {id: 199}])
      mocks.jobs.mockResolvedValueOnce([{id: 555, name: 'test-job'}]).mockResolvedValueOnce([])
      mocks.download.mockResolvedValue({
        text: async () => '{"uuid":"test-uuid"}',
      })

      const uploader = new GitlabArtifactsUploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a'],
      })

      await uploader.downloadHistory()

      expect(mocks.mkdirSync).toHaveBeenCalledTimes(1)
      expect(mocks.mkdirSync.mock.calls[0]).toEqual([dirname(historyPath), {recursive: true}])
      expect(mocks.pipelines).toHaveBeenCalledTimes(1)
      expect(mocks.pipelines.mock.calls[0]).toEqual([
        '123',
        {
          ref: 'main',
          source: 'push',
          perPage: 100,
          maxPages: 1,
        },
      ])
      expect(mocks.jobs.mock.calls[0]).to.deep.equal([
        '123',
        {
          pipelineId: 199,
          scope: 'failed',
          includeRetried: false,
          perPage: 100,
        },
      ])
      expect(mocks.jobs.mock.calls[1]).to.deep.equal([
        '123',
        {
          pipelineId: 199,
          scope: 'success',
          includeRetried: false,
          perPage: 100,
        },
      ])
      expect(mocks.download).toHaveBeenCalledTimes(1)
      expect(mocks.download.mock.calls[0]).toEqual([
        '123',
        {
          jobId: 555,
          artifactPath: 'reports/history/history.json',
        },
      ])
      expect(mocks.writeFileSync).toHaveBeenCalledTimes(1)
      expect(mocks.writeFileSync.mock.calls[0]).toEqual([historyPath, '{"uuid":"test-uuid"}'])
    })

    it('throws when there are not enough pipelines to resolve a previous job', async () => {
      mocks.pipelines.mockResolvedValue([{id: 200}])

      const uploader = new GitlabArtifactsUploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a'],
      })

      const result = uploader.downloadHistory()
      await expect(result).rejects.toBeInstanceOf(Error)
      await expect(result).rejects.toThrow('Not enough pipelines found')
    })

    it('throws a wrapped error when artifacts download fails', async () => {
      mocks.pipelines.mockResolvedValue([{id: 200}, {id: 199}])
      mocks.jobs.mockResolvedValueOnce([{id: 555, name: 'test-job'}]).mockResolvedValueOnce([])
      mocks.download.mockRejectedValue(new Error('network failure'))

      const uploader = new GitlabArtifactsUploader({
        historyPath,
        reportPath,
        plugins: ['plugin-a'],
      })

      const result = uploader.downloadHistory()
      await expect(result).rejects.toBeInstanceOf(Error)
      await expect(result).rejects.toThrow(
        "Failed to download history artifact from job ID: '555'. Err: 'network failure'",
      )
    })
  })
})
