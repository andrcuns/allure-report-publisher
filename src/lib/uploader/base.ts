/* eslint-disable unicorn/no-array-for-each */
import {mkdirSync, readFileSync} from 'node:fs'
import path from 'node:path'

import {ciInfo} from '../../utils/ci.js'
import {globPaths} from '../../utils/glob.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'
import {GithubCiInfo} from '../ci/info/github.js'
import {GitlabCiInfo} from '../ci/info/gitlab.js'

export abstract class BaseUploader {
  protected copyLatest: boolean
  protected readonly bucketName: string
  protected readonly parallel: number
  protected readonly reportPath: string
  protected readonly historyPath: string
  protected readonly plugins: string[]
  protected readonly prefix: string | undefined
  protected readonly baseUrl: string | undefined
  private _runId: string | undefined
  private _reportFiles: string[] | undefined

  constructor(opts: {
    bucket: string
    copyLatest: boolean
    historyPath: string
    output: string
    parallel: number
    plugins: string[]
    baseUrl?: string
    prefix?: string
  }) {
    this.bucketName = opts.bucket
    this.prefix = opts.prefix
    this.baseUrl = opts.baseUrl
    this.copyLatest = opts.copyLatest
    this.parallel = opts.parallel
    this.reportPath = opts.output
    this.historyPath = opts.historyPath
    this.plugins = opts.plugins
  }

  protected abstract uploadHistory(): Promise<void>
  protected abstract uploadReport(): Promise<void>
  protected abstract reportUrlBase(): string
  protected abstract createLatestCopy(): Promise<void>

  protected get ciInfo(): GithubCiInfo | GitlabCiInfo | undefined {
    return ciInfo
  }

  protected get runId() {
    if (this._runId !== undefined) return this._runId

    this._runId = this.ciInfo?.runId || this.historyUuid()
    return this._runId
  }

  public async downloadHistory() {
    const historyDir = path.dirname(this.historyPath)
    logger.debug(`Creating destination directory for history file at ${historyDir}`)
    mkdirSync(historyDir, {recursive: true})
  }

  public async upload() {
    await spin(this.uploadHistory(), 'uploading history file')
    await spin(this.uploadReport(), 'uploading report files')
    if (this.copyLatest) await spin(this.createLatestCopy(), 'creating latest report copy')
    this.outputReportUrls()
  }

  protected async getReportFiles() {
    if (this._reportFiles) return this._reportFiles

    this._reportFiles = (
      await Promise.all(this.plugins.map(() => globPaths(`${this.reportPath}/**/*`, {nodir: true})))
    ).flat()

    return this._reportFiles
  }

  protected historyFileName() {
    return path.basename(this.historyPath)
  }

  protected historyUuid() {
    const content = readFileSync(this.historyPath, 'utf8')
    const lines = content
      .trim()
      .split('\n')
      .filter((line) => line.trim() !== '')
    if (lines.length === 0) throw new Error(`History file is empty: ${this.historyPath}`)

    const {uuid} = JSON.parse(lines.at(-1) as string)
    return uuid
  }

  protected key(...components: (null | string | undefined)[]): string {
    return [this.prefix, ...components]
      .filter(Boolean)
      .map((c) => c?.replace(/\/$/, ''))
      .join('/')
  }

  protected outputReportUrls() {
    logger.section('Report URLs')
    const urls = this.getReportUrls()

    logger.success('Fetching current run urls:')
    urls.run.forEach((url) => logger.info(`- ${url}`))

    if (this.copyLatest && urls.latest) {
      logger.success('Fetching latest report urls:')
      urls.latest.forEach((url) => logger.info(`- ${url}`))
    }
  }

  protected getReportUrls(): {run: string[]; latest?: string[]} {
    const urls = {
      run: [`${this.reportUrlBase()}/${this.runId}/index.html`],
      latest: [`${this.reportUrlBase()}/latest/index.html`],
    }

    if (this.plugins.length > 1) {
      urls.run.push(...this.plugins.map((plugin) => `${this.reportUrlBase()}/${this.runId}/${plugin}/index.html`))
      urls.latest.push(...this.plugins.map((plugin) => `${this.reportUrlBase()}/latest/${plugin}/index.html`))
    }

    return urls
  }
}
