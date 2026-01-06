import {Storage} from '@google-cloud/storage'
import path from 'node:path'
import pAll from 'p-all'

import {globalConfig} from '../../../utils/global-config.js'
import {logger} from '../../../utils/logger.js'
import {BaseCloudUploader} from './base.js'

export class GcsUploader extends BaseCloudUploader {
  private _reportUrlBase: string | undefined
  private readonly storageClient: Storage = new Storage()

  protected reportUrlBase() {
    if (this._reportUrlBase) return this._reportUrlBase

    this._reportUrlBase = [this.baseUrl || 'https://storage.googleapis.com', this.bucketName, this.prefix]
      .filter((components) => components !== undefined)
      .join('/')
    return this._reportUrlBase
  }

  public async downloadHistory() {
    await super.downloadHistory()

    const key = this.key(this.historyFileName())
    logger.debug(`Downloading history file from gs://${this.bucketName}/${key}`)
    await this.storageClient.bucket(this.bucketName).file(key).download({destination: this.historyPath})
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

    await pAll(uploads, {concurrency: globalConfig.parallel})
  }

  protected async createLatestCopy() {
    logger.debug(`Creating latest report copy with concurrency: ${this.parallel}`)
    const copies = (await this.getReportFiles()).map((filePath) => {
      const sourceKey = this.key(this.runId, path.relative(this.reportPath, filePath))
      const destinationKey = this.key('latest', path.relative(this.reportPath, filePath))
      return () => this.copyFile({sourceKey, destinationKey})
    })

    await pAll(copies, {concurrency: globalConfig.parallel})
  }

  private async uploadFile(opts: {filePath: string; key: string}) {
    logger.debug(`- uploading '${opts.filePath}' to 'gs://${this.bucketName}/${opts.key}'`)
    return this.storageClient.bucket(this.bucketName).upload(opts.filePath, {destination: opts.key})
  }

  private async copyFile(opts: {sourceKey: string; destinationKey: string}) {
    const destination = this.storageClient.bucket(this.bucketName).file(opts.destinationKey)

    logger.debug(
      `- copying 'gs://${this.bucketName}/${opts.sourceKey}' to 'gs://${this.bucketName}/${opts.destinationKey}'`,
    )
    await this.storageClient.bucket(this.bucketName).file(opts.sourceKey).copy(destination)
  }
}
