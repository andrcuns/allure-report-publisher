import {BaseCloudUploadCommand} from '../../lib/commands/upload.js'
import {S3Uploader} from '../../lib/uploader/cloud/s3.js'

export default class S3 extends BaseCloudUploadCommand {
  static override description = 'Generate and upload allure report to s3 bucket'

  protected getUploader(opts: {
    bucket: string
    copyLatest: boolean
    parallel: number
    historyPath: string
    output: string
    plugins: string[]
    baseUrl?: string
    prefix?: string
  }) {
    return new S3Uploader(opts)
  }
}
