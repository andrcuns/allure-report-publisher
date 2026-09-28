import dedent from 'dedent'
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest'

import {ReportSummary} from '../../../../src/lib/ci/pr/report-summary.js'
import {UrlSectionBuilder} from '../../../../src/lib/ci/pr/url-section-builder.js'
import {GitlabCiProvider} from '../../../../src/lib/ci/providers/gitlab.js'

const gitlabClientStub = vi.hoisted(() => ({
  MergeRequests: {
    show: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
    edit: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
  },
  MergeRequestNotes: {
    all: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
    create: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
    edit: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
  },
}))

vi.mock('../../../../src/lib/ci/utils.js', () => ({gitlabClient: gitlabClientStub}))

describe('GitlabCiProvider', () => {
  let originalEnv: NodeJS.ProcessEnv
  let urlSectionBuilder: UrlSectionBuilder

  beforeEach(() => {
    vi.resetAllMocks()
    originalEnv = {...process.env}

    process.env.CI_PROJECT_ID = '123'
    process.env.CI_MERGE_REQUEST_IID = '42'
    process.env.CI_JOB_NAME = 'test-job'
    process.env.CI_SERVER_URL = 'https://gitlab.com'
    process.env.CI_PROJECT_PATH = 'group/project'

    const summary = new ReportSummary({stats: {}, status: 'passed'}, false)
    vi.spyOn(summary, 'table').mockReturnValue('test table')
    vi.spyOn(summary, 'status').mockReturnValue('✅')

    urlSectionBuilder = new UrlSectionBuilder({
      buildName: 'test-job',
      reportUrl: 'https://example.com/report',
      shaUrl: '[abc123](https://gitlab.com/commit/abc123)',
      shouldAddSummaryTable: true,
      shouldCollapseSummary: false,
      summary,
    })
  })

  afterEach(() => {
    process.env = originalEnv
  })

  describe('addReportSection()', () => {
    it('updates MR description when mode is description', async () => {
      gitlabClientStub.MergeRequests.show.mockResolvedValue({
        id: 1,
        description: 'Original description',
      })
      gitlabClientStub.MergeRequests.edit.mockResolvedValue(undefined)

      const provider = new GitlabCiProvider(urlSectionBuilder, 'description')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequests.show).toHaveBeenCalledTimes(1)
      expect(gitlabClientStub.MergeRequests.edit).toHaveBeenCalledTimes(1)
      expect(gitlabClientStub.MergeRequests.edit.mock.calls[0][0]).to.equal('123')
      expect(gitlabClientStub.MergeRequests.edit.mock.calls[0][1]).to.equal(42)
      expect(gitlabClientStub.MergeRequests.edit.mock.calls[0][2]).to.have.property('description')
    })

    it('creates new comment when mode is comment and no existing comment', async () => {
      gitlabClientStub.MergeRequestNotes.all.mockResolvedValue([])
      gitlabClientStub.MergeRequestNotes.create.mockResolvedValue({id: 999})

      const provider = new GitlabCiProvider(urlSectionBuilder, 'comment')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequestNotes.all).toHaveBeenCalledTimes(1)
      expect(gitlabClientStub.MergeRequestNotes.create).toHaveBeenCalledTimes(1)
      expect(gitlabClientStub.MergeRequestNotes.create.mock.calls[0][0]).to.equal('123')
      expect(gitlabClientStub.MergeRequestNotes.create.mock.calls[0][1]).to.equal(42)
    })

    it('updates existing comment when mode is comment and comment exists', async () => {
      const existingComment = {
        id: 777,
        body: dedent`<!-- allure -->
          # 📝 Test Report
          <!-- jobs -->
          <!-- test-job -->
          **test-job**: ✅ [test report](https://example.com/old-report)
          <!-- test-job -->
          <!-- jobs -->
          <!-- allurestop -->`,
      }

      gitlabClientStub.MergeRequestNotes.all.mockResolvedValue([existingComment])
      gitlabClientStub.MergeRequestNotes.edit.mockResolvedValue({id: 777})

      const provider = new GitlabCiProvider(urlSectionBuilder, 'comment')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequestNotes.all).toHaveBeenCalledTimes(1)
      expect(gitlabClientStub.MergeRequestNotes.edit).toHaveBeenCalledTimes(1)
      expect(gitlabClientStub.MergeRequestNotes.edit.mock.calls[0][0]).to.equal('123')
      expect(gitlabClientStub.MergeRequestNotes.edit.mock.calls[0][1]).to.equal(42)
      expect(gitlabClientStub.MergeRequestNotes.edit.mock.calls[0][2]).to.equal(777)
    })

    it('throws error when MR IID not available for description mode', async () => {
      delete process.env.CI_MERGE_REQUEST_IID

      const provider = new GitlabCiProvider(urlSectionBuilder, 'description')

      const result = provider.addReportSection()
      await expect(result).rejects.toBeInstanceOf(Error)
      await expect(result).rejects.toThrow('Could not detect merge request iid')
    })

    it('throws error when MR IID not available for comment mode', async () => {
      delete process.env.CI_MERGE_REQUEST_IID

      const provider = new GitlabCiProvider(urlSectionBuilder, 'comment')

      const result = provider.addReportSection()
      await expect(result).rejects.toBeInstanceOf(Error)
      await expect(result).rejects.toThrow('Could not detect merge request iid')
    })

    it('handles empty MR description', async () => {
      gitlabClientStub.MergeRequests.show.mockResolvedValue({
        id: 1,
        description: null,
      })
      gitlabClientStub.MergeRequests.edit.mockResolvedValue(undefined)

      const provider = new GitlabCiProvider(urlSectionBuilder, 'description')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequests.edit).toHaveBeenCalledTimes(1)
    })

    it('fetches all comments with correct parameters', async () => {
      gitlabClientStub.MergeRequestNotes.all.mockResolvedValue([])
      gitlabClientStub.MergeRequestNotes.create.mockResolvedValue({id: 999})

      const provider = new GitlabCiProvider(urlSectionBuilder, 'comment')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequestNotes.all.mock.calls[0]).to.deep.equal([
        '123',
        42,
        {
          sort: 'asc',
          orderBy: 'created_at',
          perPage: 100,
        },
      ])
    })
  })
})
