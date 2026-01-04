import {ReportSummary} from './report-summary.js'

type UrlSectionBuilderArgs = {
  buildName: string
  reportUrl: string
  summary: ReportSummary
  shouldAddSummaryTable: boolean
  shouldCollapseSummary?: boolean
  reportTitle?: string
  shaUrl?: string
}

export class UrlSectionBuilder {
  private static readonly DESCRIPTION_PATTERN = /<!-- allure -->[\s\S]+<!-- allurestop -->/
  private static readonly JOBS_PATTERN = /<!-- jobs -->(?<jobs>[\s\S]+)<!-- jobs -->/
  private readonly buildName: string
  private readonly shouldAddSummaryTable: boolean
  private readonly shouldCollapseSummary: boolean
  private readonly reportTitle: string
  private readonly reportUrl: string
  private readonly summary: ReportSummary
  private readonly shaUrl?: string
  private _heading?: string
  private _jobEntry?: string
  private _jobEntryPattern?: RegExp

  constructor(args: UrlSectionBuilderArgs) {
    this.reportUrl = args.reportUrl
    this.buildName = args.buildName
    this.summary = args.summary
    this.shaUrl = args.shaUrl
    this.shouldAddSummaryTable = args.shouldAddSummaryTable
    this.shouldCollapseSummary = args.shouldCollapseSummary || false
    this.reportTitle = args.reportTitle || '📝 Test Report'
  }

  static match(urlsBlock: string): boolean {
    return this.DESCRIPTION_PATTERN.test(urlsBlock)
  }

  updatedPrDescription(prDescription?: string) {
    const strippedDescription = (prDescription || '').trim()

    if (strippedDescription === '') {
      return this.urlSection({separator: false})
    }

    if (!UrlSectionBuilder.DESCRIPTION_PATTERN.test(prDescription!)) {
      const section = this.urlSection()
      return `${prDescription}\n\n${section}`
    }

    const jobEntries = this.jobsSection(prDescription!)
    const match = prDescription!.match(UrlSectionBuilder.DESCRIPTION_PATTERN)
    const nonEmpty = strippedDescription !== match![0]
    const section = this.urlSection({jobEntries, separator: nonEmpty})

    return prDescription!.replace(UrlSectionBuilder.DESCRIPTION_PATTERN, section)
  }

  commentBody(prComment?: string): string {
    if (!prComment) {
      return this.urlSection({separator: false})
    }

    const jobEntries = this.jobsSection(prComment)
    return this.urlSection({jobEntries, separator: false})
  }

  private heading(): string {
    if (this._heading) return this._heading

    this._heading =
      `# ${this.reportTitle}\n` +
      `[\`allure-report-publisher\`](https://github.com/andrcuns/allure-report-publisher) ` +
      `generated test report!`

    return this._heading
  }

  private jobEntry() {
    if (this._jobEntry) return this._jobEntry

    const entry: string[] = []
    const status = this.summary.status()

    entry.push(
      `<!-- ${this.buildName} -->`,
      `**${this.buildName}**: ${status} [test report](${this.reportUrl})${this.shaUrl ? ` for ${this.shaUrl}` : ''}`,
    )
    if (this.shouldAddSummaryTable) this.addSummaryTable(entry)
    entry.push(`<!-- ${this.buildName} -->`)

    this._jobEntry = entry.join('\n')
    return this._jobEntry
  }

  private addSummaryTable(entry: string[]) {
    if (this.shouldCollapseSummary) entry.push('<details>', '<summary>expand test summary</summary>\n')
    if (this.shouldAddSummaryTable) entry.push(this.summary.table())
    if (this.shouldCollapseSummary) entry.push('</details>')
  }

  private jobEntryPattern(): RegExp {
    if (this._jobEntryPattern) return this._jobEntryPattern

    // Escape special regex characters in build name
    const escapedBuildName = this.buildName.replaceAll(/[.*+?^${}()|[\]\\]/g, String.raw`\$&`)
    this._jobEntryPattern = new RegExp(`<!-- ${escapedBuildName} -->[\\s\\S]+<!-- ${escapedBuildName} -->`, 'g')

    return this._jobEntryPattern
  }

  private urlSection(options: {jobEntries?: string; separator?: boolean} = {}) {
    const jobEntries = options.jobEntries === undefined ? this.jobEntry() : options.jobEntries
    const separator = options.separator === undefined ? true : options.separator

    const parts = [
      '<!-- allure -->',
      separator ? '---' : undefined,
      this.heading(),
      '<!-- jobs -->',
      jobEntries,
      '<!-- jobs -->',
      '<!-- allurestop -->',
    ]

    return parts.filter(Boolean).join('\n').trim()
  }

  private jobsSection(body: string) {
    const match = body.match(UrlSectionBuilder.JOBS_PATTERN)
    if (!match || !match.groups) {
      throw new Error('Jobs section not found in body')
    }

    const {jobs} = match.groups
    const pattern = this.jobEntryPattern()
    const entry = this.jobEntry()

    if (pattern.test(jobs)) {
      return jobs.replace(pattern, entry).trim()
    }

    return `${jobs.trim()}\n\n${entry}`
  }
}
