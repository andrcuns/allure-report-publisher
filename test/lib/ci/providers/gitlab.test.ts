/* eslint-disable @typescript-eslint/no-explicit-any */
import dedent from 'dedent'
import esmock from 'esmock'
import * as sinon from 'sinon'

import {ReportSummary} from '../../../../src/lib/ci/pr/report-summary.js'
import {UrlSectionBuilder} from '../../../../src/lib/ci/pr/url-section-builder.js'
import {GitlabCiProvider} from '../../../../src/lib/ci/providers/gitlab.js'
import {expect} from '../../../support/setup.js'

describe('GitlabCiProvider', () => {
  let originalEnv: NodeJS.ProcessEnv
  let urlSectionBuilder: UrlSectionBuilder
  let CiProvider: typeof GitlabCiProvider
  let gitlabClientStub: any

  beforeEach(async () => {
    originalEnv = {...process.env}

    process.env.CI_PROJECT_ID = '123'
    process.env.CI_MERGE_REQUEST_IID = '42'
    process.env.CI_JOB_NAME = 'test-job'
    process.env.CI_SERVER_URL = 'https://gitlab.com'
    process.env.CI_PROJECT_PATH = 'group/project'

    gitlabClientStub = {
      MergeRequests: {
        show: sinon.stub(),
        edit: sinon.stub(),
      },
      MergeRequestNotes: {
        all: sinon.stub(),
        create: sinon.stub(),
        edit: sinon.stub(),
      },
    }

    const summaryStub = sinon.createStubInstance(ReportSummary)
    summaryStub.table.returns('test table')
    summaryStub.status.returns('✅')

    urlSectionBuilder = new UrlSectionBuilder({
      buildName: 'test-job',
      reportUrl: 'https://example.com/report',
      shaUrl: '[abc123](https://gitlab.com/commit/abc123)',
      shouldAddSummaryTable: true,
      shouldCollapseSummary: false,
      summary: summaryStub,
    })

    const module = await esmock('../../../../src/lib/ci/providers/gitlab.js', {
      '../../../../src/lib/ci/utils.js': {
        gitlabClient: gitlabClientStub,
      },
    })

    CiProvider = module.GitlabCiProvider
  })

  afterEach(() => {
    process.env = originalEnv
  })

  describe('addReportSection()', () => {
    it('updates MR description when mode is description', async () => {
      gitlabClientStub.MergeRequests.show.resolves({
        id: 1,
        description: 'Original description',
      })
      gitlabClientStub.MergeRequests.edit.resolves()

      const provider = new CiProvider(urlSectionBuilder, 'description')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequests.show.calledOnce).to.be.true
      expect(gitlabClientStub.MergeRequests.edit.calledOnce).to.be.true
      expect(gitlabClientStub.MergeRequests.edit.firstCall.args[0]).to.equal('123')
      expect(gitlabClientStub.MergeRequests.edit.firstCall.args[1]).to.equal(42)
      expect(gitlabClientStub.MergeRequests.edit.firstCall.args[2]).to.have.property('description')
    })

    it('creates new comment when mode is comment and no existing comment', async () => {
      gitlabClientStub.MergeRequestNotes.all.resolves([])
      gitlabClientStub.MergeRequestNotes.create.resolves({id: 999})

      const provider = new CiProvider(urlSectionBuilder, 'comment')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequestNotes.all.calledOnce).to.be.true
      expect(gitlabClientStub.MergeRequestNotes.create.calledOnce).to.be.true
      expect(gitlabClientStub.MergeRequestNotes.create.firstCall.args[0]).to.equal('123')
      expect(gitlabClientStub.MergeRequestNotes.create.firstCall.args[1]).to.equal(42)
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

      gitlabClientStub.MergeRequestNotes.all.resolves([existingComment])
      gitlabClientStub.MergeRequestNotes.edit.resolves({id: 777})

      const provider = new CiProvider(urlSectionBuilder, 'comment')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequestNotes.all.calledOnce).to.be.true
      expect(gitlabClientStub.MergeRequestNotes.edit.calledOnce).to.be.true
      expect(gitlabClientStub.MergeRequestNotes.edit.firstCall.args[0]).to.equal('123')
      expect(gitlabClientStub.MergeRequestNotes.edit.firstCall.args[1]).to.equal(42)
      expect(gitlabClientStub.MergeRequestNotes.edit.firstCall.args[2]).to.equal(777)
    })

    it('throws error when MR IID not available for description mode', async () => {
      delete process.env.CI_MERGE_REQUEST_IID

      const provider = new CiProvider(urlSectionBuilder, 'description')

      expect(provider.addReportSection()).to.be.rejectedWith(Error, 'Could not detect merge request iid')
    })

    it('throws error when MR IID not available for comment mode', async () => {
      delete process.env.CI_MERGE_REQUEST_IID

      const provider = new CiProvider(urlSectionBuilder, 'comment')

      expect(provider.addReportSection()).to.be.rejectedWith(Error, 'Could not detect merge request iid')
    })

    it('handles empty MR description', async () => {
      gitlabClientStub.MergeRequests.show.resolves({
        id: 1,
        description: null,
      })
      gitlabClientStub.MergeRequests.edit.resolves()

      const provider = new CiProvider(urlSectionBuilder, 'description')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequests.edit.calledOnce).to.be.true
    })

    it('fetches all comments with correct parameters', async () => {
      gitlabClientStub.MergeRequestNotes.all.resolves([])
      gitlabClientStub.MergeRequestNotes.create.resolves({id: 999})

      const provider = new CiProvider(urlSectionBuilder, 'comment')

      await provider.addReportSection()

      expect(gitlabClientStub.MergeRequestNotes.all.firstCall.args).to.deep.equal([
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
