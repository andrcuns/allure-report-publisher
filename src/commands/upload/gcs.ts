import {BaseCloudUploadCommand} from '../../lib/commands/upload.js'
import {GcsUploader} from '../../lib/uploader/cloud/gcs.js'

export default class Gcs extends BaseCloudUploadCommand {
  static override description = 'Generate and upload allure report to gcs bucket'

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
    return new GcsUploader(opts)
  }
}
