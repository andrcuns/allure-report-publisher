import dedent from 'dedent'
import {createStubInstance} from 'sinon'

import {ReportSummary} from '../../../../src/lib/ci/pr/report-summary.js'
import {UrlSectionBuilder} from '../../../../src/lib/ci/pr/url-section-builder.js'
import {expect} from '../../../support/setup.js'

describe('UrlSectionBuilder', () => {
  const defaultArgs = {
    buildName: 'Test Build',
    reportUrl: 'https://example.com/report',
    shaUrl: '[abc123](https://github.com/user/repo/commit/abc123)',
    shouldAddSummaryTable: true,
    shouldCollapseSummary: false,
    summary: createStubInstance(ReportSummary, {
      table: '[TEST SUMMARY TABLE]',
      status: '✅',
    }),
  }

  describe('match()', () => {
    it('returns true when URL block contains allure markers', () => {
      const urlBlock = '<!-- allure -->\nSome content\n<!-- allurestop -->'

      expect(UrlSectionBuilder.match(urlBlock)).to.be.true
    })

    it('returns false when URL block does not contain allure markers', () => {
      const urlBlock = 'Some regular content without markers'

      expect(UrlSectionBuilder.match(urlBlock)).to.be.false
    })
  })

  describe('updatedDescription()', () => {
    it('creates new section when description is empty', () => {
      const builder = new UrlSectionBuilder(defaultArgs)

      expect(builder.updatedDescription('')).to.equal(dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Test Build -->
        **Test Build**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('appends section to existing description without markers', () => {
      const builder = new UrlSectionBuilder(defaultArgs)
      const existingDescription = 'This is my PR description'

      expect(builder.updatedDescription(existingDescription)).to.equal(dedent`This is my PR description

        <!-- allure -->
        ---
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Test Build -->
        **Test Build**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('updates existing section in description', () => {
      const builder = new UrlSectionBuilder(defaultArgs)
      const existingDescription = dedent`My PR
        ---
        <!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Other Build -->
        **Other Build**: ✅ [test report](https://other.com) for [other](https://github.com)
        <!-- Other Build -->
        <!-- jobs -->
        <!-- allurestop -->`

      expect(builder.updatedDescription(existingDescription)).to.equal(dedent`My PR
        ---
        <!-- allure -->
        ---
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Other Build -->
        **Other Build**: ✅ [test report](https://other.com) for [other](https://github.com)
        <!-- Other Build -->

        <!-- Test Build -->
        **Test Build**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('preserves multiple job entries in jobs section', () => {
      const args = {...defaultArgs, buildName: 'Build 2'}
      const builder = new UrlSectionBuilder(args)
      const existingDescription = dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Build 1 -->
        **Build 1**: ✅ [test report](https://example.com/1) for [sha1](https://github.com/sha1)
        <!-- Build 1 -->
        <!-- jobs -->
        <!-- allurestop -->`

      expect(builder.updatedDescription(existingDescription)).to.equal(dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Build 1 -->
        **Build 1**: ✅ [test report](https://example.com/1) for [sha1](https://github.com/sha1)
        <!-- Build 1 -->

        <!-- Build 2 -->
        **Build 2**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Build 2 -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('updates existing job entry when build name matches', () => {
      const builder = new UrlSectionBuilder(defaultArgs)
      const existingDescription = dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Test Build -->
        **Test Build**: ❌ [test report](https://other.com) for [other](https://github.com)
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`

      expect(builder.updatedDescription(existingDescription)).to.equal(dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Test Build -->
        **Test Build**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('uses custom report title when provided', () => {
      const args = {...defaultArgs, reportTitle: '🧪 My Custom Report'}
      const builder = new UrlSectionBuilder(args)

      expect(builder.updatedDescription('')).to.equal(dedent`<!-- allure -->
        # 🧪 My Custom Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Test Build -->
        **Test Build**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('includes separator when description has content', () => {
      const builder = new UrlSectionBuilder(defaultArgs)
      const description = 'Some content'

      const result = builder.updatedDescription(description)

      expect(result).to.include('---')
      expect(result.startsWith('Some content\n\n<!-- allure -->\n---\n')).to.be.true
    })
  })

  describe('commentBody()', () => {
    it('creates new comment body when comment is undefined', () => {
      const builder = new UrlSectionBuilder(defaultArgs)
      const result = builder.commentBody()

      expect(result).to.equal(dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Test Build -->
        **Test Build**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('updates existing comment with jobs section', () => {
      const builder = new UrlSectionBuilder(defaultArgs)
      const existingComment = dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Other Build -->
        **Other Build**: ✅ [test report](https://other.com) for [other](https://github.com)
        <!-- Other Build -->
        <!-- jobs -->
        <!-- allurestop -->`

      expect(builder.commentBody(existingComment)).to.equal(dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Other Build -->
        **Other Build**: ✅ [test report](https://other.com) for [other](https://github.com)
        <!-- Other Build -->

        <!-- Test Build -->
        **Test Build**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('adds job entry to existing jobs', () => {
      const args = {...defaultArgs, buildName: 'Build 2'}
      const builder = new UrlSectionBuilder(args)
      const existingComment = dedent`<!-- allure -->
        # 📝 Test Report
        <!-- jobs -->
        <!-- Build 1 -->
        **Build 1**: ✅ [test report](https://example.com/1) for [sha](https://github.com)
        <!-- Build 1 -->
        <!-- jobs -->
        <!-- allurestop -->`

      expect(builder.commentBody(existingComment)).to.equal(dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Build 1 -->
        **Build 1**: ✅ [test report](https://example.com/1) for [sha](https://github.com)
        <!-- Build 1 -->

        <!-- Build 2 -->
        **Build 2**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        [TEST SUMMARY TABLE]
        <!-- Build 2 -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('collapses summary when collapseSummary is true', () => {
      const args = {...defaultArgs, shouldCollapseSummary: true}
      const builder = new UrlSectionBuilder(args)

      expect(builder.commentBody()).to.equal(dedent`<!-- allure -->
        # 📝 Test Report
        [\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) generated test report!
        <!-- jobs -->
        <!-- Test Build -->
        **Test Build**: ✅ [test report](https://example.com/report) for [abc123](https://github.com/user/repo/commit/abc123)
        <details>
        <summary>expand test summary</summary>

        [TEST SUMMARY TABLE]
        </details>
        <!-- Test Build -->
        <!-- jobs -->
        <!-- allurestop -->`)
    })

    it('does not collapse summary by default', () => {
      const builder = new UrlSectionBuilder(defaultArgs)

      const result = builder.commentBody()

      expect(result).not.to.include('<details>')
      expect(result).not.to.include('</details>')
    })
  })
})
