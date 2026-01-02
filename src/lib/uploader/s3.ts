import {
  CopyObjectCommand,
  GetObjectCommand,
  NoSuchKey,
  PutObjectCommand,
  S3Client,
  waitUntilObjectExists,
} from '@aws-sdk/client-s3'
import {lookup} from 'mime-types'
import {readFileSync, writeFileSync} from 'node:fs'
import path from 'node:path'
import pAll from 'p-all'

import {config} from '../../utils/config.js'
import {logger} from '../../utils/logger.js'
import {BaseUploader} from './base.js'

export class S3Uploader extends BaseUploader {
  private _reportUrlBase: string | undefined
  private readonly s3Client: S3Client = new S3Client({
    endpoint: this.awsEndpoint,
    forcePathStyle: this.forcePathStyle,
    region: process.env.AWS_REGION || 'us-east-1',
  })

  private get awsEndpoint() {
    return process.env.AWS_ENDPOINT
  }

  private get forcePathStyle() {
    return process.env.AWS_FORCE_PATH_STYLE === 'true'
  }

  private get region() {
    return process.env.AWS_REGION || 'us-east-1'
  }

  protected reportUrlBase() {
    if (this._reportUrlBase) return this._reportUrlBase

    let base = `https://${this.bucketName}.s3.${this.region}.amazonaws.com`
    if (this.awsEndpoint) {
      base = this.forcePathStyle ? `${this.awsEndpoint}/${this.bucketName}` : this.awsEndpoint
    }

    this._reportUrlBase = this.prefix ? `${base}/${this.prefix}` : base
    return this._reportUrlBase
  }

  public async downloadHistory() {
    await super.downloadHistory()

    const key = this.key(this.historyFileName())
    logger.debug(`Downloading history file from s3://${this.bucketName}/${key}`)

    try {
      const response = await this.s3Client.send(
        new GetObjectCommand({
          Bucket: this.bucketName,
          Key: key,
        }),
      )

      if (!response.Body) {
        throw new Error('Received empty response body when downloading history file')
      }

      const content = await response.Body.transformToString()
      if (content.trim().length === 0) throw new Error('Received empty response body when downloading history file')

      writeFileSync(this.historyPath, content, 'utf8')
      logger.debug(`History file downloaded successfully to ${this.historyPath}`)
    } catch (error) {
      throw error instanceof NoSuchKey ? new Error(`History file not found!`) : error
    }
  }

  protected async uploadHistory() {
    logger.debug('Uploading history file')
    await this.uploadFile({
      filePath: this.historyPath,
      key: this.key(this.historyFileName()),
    })
  }

  protected async uploadReport() {
    logger.debug(`Uploading report files with concurrency: ${this.parallel}`)
    const uploads = (await this.getReportFiles()).map((filePath) => {
      const key = this.key(this.runId, path.relative(this.reportPath, filePath))
      return () => this.uploadFile({filePath, key})
    })

    await pAll(uploads, {concurrency: config.parallel})
  }

  protected async createLatestCopy() {
    logger.debug(`Creating latest report copy with concurrency: ${this.parallel}`)
    const copies = (await this.getReportFiles()).map((filePath) => {
      const sourceKey = this.key(this.runId, path.relative(this.reportPath, filePath))
      const destinationKey = this.key('latest', path.relative(this.reportPath, filePath))
      return () => this.copyFile({sourceKey, destinationKey})
    })

    await pAll(copies, {concurrency: config.parallel})
  }

  private async uploadFile(opts: {cacheControl?: string; filePath: string; key: string}) {
    const content = readFileSync(opts.filePath)
    const contentType = lookup(opts.filePath) || 'application/octet-stream'

    logger.debug(`- uploading '${opts.filePath}' to 's3://${this.bucketName}/${opts.key}' (type: ${contentType})`)
    return this.s3Client.send(
      new PutObjectCommand({
        Body: content,
        Bucket: this.bucketName,
        Key: opts.key,
        CacheControl: opts.cacheControl || 'max-age=3600',
        ContentType: contentType,
      }),
    )
  }

  private async copyFile(opts: {sourceKey: string; destinationKey: string}) {
    const source = `${this.bucketName}/${opts.sourceKey}`

    logger.debug(`- copying 's3://${source}' to 's3://${this.bucketName}/${opts.destinationKey}'`)
    await this.s3Client.send(
      new CopyObjectCommand({
        CopySource: source,
        Bucket: this.bucketName,
        Key: opts.destinationKey,
      }),
    )
    await waitUntilObjectExists(
      {client: this.s3Client, maxWaitTime: 60},
      {Bucket: this.bucketName, Key: opts.destinationKey},
    )
  }
}
