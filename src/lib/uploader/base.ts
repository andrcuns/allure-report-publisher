import {glob} from 'glob'

export abstract class BaseUploader {
  protected readonly bucketName: string
  protected readonly prefix: string
  protected readonly baseUrl: string
  protected readonly copyLatest: boolean
  protected readonly parallel: number
  protected readonly reportPath: string
  protected readonly historyPath: string
  protected readonly plugins: string[]

  constructor(opts: {
    baseUrl: string
    bucket: string
    copyLatest: boolean
    historyPath: string
    output: string
    parallel: number
    plugins: string[]
    prefix: string
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

  public abstract downloadHistory(): Promise<void>
  public abstract upload(): Promise<void>
  public abstract getReportUrls(): Promise<string[]>

  protected abstract uploadHistory(): Promise<void>

  protected async getReportFiles() {
    return this.plugins.map((plugin) => [
      plugin,
      glob(`${this.reportPath}/**/*`, {
        absolute: true,
        nodir: false,
        windowsPathsNoEscape: true,
      }),
    ])
  }
}
