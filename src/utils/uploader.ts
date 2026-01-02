import {BaseUploader} from '../lib/uploader/base.js'
import {GitlabArtifactsUploader} from '../lib/uploader/gitlab-artifacts.js'
import {S3Uploader} from '../lib/uploader/s3.js'

export function getUploader(
  type: string,
  opts: {
    bucket: string
    copyLatest: boolean
    parallel: number
    historyPath: string
    output: string
    plugins: string[]
    baseUrl?: string
    prefix?: string
  },
): BaseUploader {
  switch (type) {
    case 'gitlab-artifacts': {
      return new GitlabArtifactsUploader(opts)
    }

    // case 'gcs': {
    //   const {GCSUploader} = require('./gcs.js')
    //   return new GCSUploader(opts)
    // }

    case 's3': {
      return new S3Uploader(opts)
    }

    default: {
      throw new Error(`Unsupported uploader type: ${type}`)
    }
  }
}
