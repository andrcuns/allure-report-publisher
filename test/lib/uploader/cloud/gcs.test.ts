import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest'

import {GcsUploader} from '../../../../src/lib/uploader/cloud/gcs.js'

const mocks = vi.hoisted(() => ({
  download: vi.fn<(...args: unknown[]) => Promise<void>>(),
  copy: vi.fn<(...args: unknown[]) => Promise<void>>(),
  file: vi.fn<(...args: unknown[]) => unknown>(),
  upload: vi.fn<(...args: unknown[]) => Promise<void>>(),
  bucket: vi.fn<(...args: unknown[]) => unknown>(),
}))

vi.mock('@google-cloud/storage', () => ({
  Storage: class {
    bucket = mocks.bucket
  },
}))

describe('GcsUploader', () => {
  let tempDir: string
  let reportDir: string
  let historyFile: string

  let uploader: GcsUploader
  let originalEnv: NodeJS.ProcessEnv

  beforeEach(() => {
    vi.resetAllMocks()
    mocks.download.mockResolvedValue(undefined)
    mocks.copy.mockResolvedValue(undefined)
    mocks.upload.mockResolvedValue(undefined)
    mocks.file.mockReturnValue({download: mocks.download, copy: mocks.copy})
    mocks.bucket.mockReturnValue({file: mocks.file, upload: mocks.upload})
    originalEnv = {...process.env}
    delete process.env.GITHUB_RUN_ID

    tempDir = join(tmpdir(), `gcs-test-${Date.now()}`)
    reportDir = join(tempDir, 'report')
    historyFile = join(tempDir, 'history.jsonl')

    mkdirSync(reportDir, {recursive: true})
    writeFileSync(historyFile, JSON.stringify({uuid: 'test-uuid-123'}))
    writeFileSync(join(reportDir, 'index.html'), '<html></html>')
    writeFileSync(join(reportDir, 'data.json'), '{}')

    uploader = new GcsUploader({
      bucket: 'test-bucket',
      copyLatest: true,
      historyPath: historyFile,
      output: reportDir,
      parallel: 2,
      plugins: ['awesome'],
      prefix: 'reports',
    })
  })

  afterEach(() => {
    process.env = originalEnv
    rmSync(tempDir, {force: true, recursive: true})
  })

  describe('reportUrl()', () => {
    it('constructs URL from bucket and prefix', () => {
      const url = uploader.reportUrl()

      expect(url).to.equal('https://storage.googleapis.com/test-bucket/reports/test-uuid-123/index.html')
    })

    it('uses custom base URL when provided', () => {
      const customUploader = new GcsUploader({
        bucket: 'test-bucket',
        copyLatest: false,
        historyPath: historyFile,
        output: reportDir,
        parallel: 1,
        plugins: ['awesome'],
        baseUrl: 'https://custom.domain.com',
        prefix: 'reports',
      })

      const url = customUploader.reportUrl()

      expect(url).to.equal('https://custom.domain.com/test-bucket/reports/test-uuid-123/index.html')
    })

    it('constructs URL without prefix when not provided', () => {
      const noPrefixUploader = new GcsUploader({
        bucket: 'test-bucket',
        copyLatest: false,
        historyPath: historyFile,
        output: reportDir,
        parallel: 1,
        plugins: ['awesome'],
      })

      const url = noPrefixUploader.reportUrl()

      expect(url).to.equal('https://storage.googleapis.com/test-bucket/test-uuid-123/index.html')
    })
  })

  describe('downloadHistory()', () => {
    it('calls storage bucket file download with correct parameters', async () => {
      await uploader.downloadHistory()

      expect(mocks.bucket).toHaveBeenCalledWith('test-bucket')
      expect(mocks.file).toHaveBeenCalledTimes(1)
      expect(mocks.download).toHaveBeenCalledTimes(1)
      expect(mocks.download.mock.calls[0][0]).toMatchObject({
        destination: historyFile,
      })
    })

    it('constructs history file key with prefix', async () => {
      await uploader.downloadHistory()

      const [[fileKey]] = mocks.file.mock.calls
      expect(fileKey).to.equal('reports/history.jsonl')
    })
  })

  describe('upload()', () => {
    beforeEach(async () => {
      await uploader.upload()
    })

    it('calls bucket upload with history file', async () => {
      expect(mocks.bucket).toHaveBeenCalledWith('test-bucket')
      expect(mocks.upload.mock.calls[0][0]).to.equal(historyFile)
    })

    it('uses correct destination key for history file', async () => {
      const [[, uploadOptions]] = mocks.upload.mock.calls
      expect(uploadOptions).toHaveProperty('destination', 'reports/history.jsonl')
    })

    it('uploads all report files to bucket', async () => {
      expect(mocks.upload).toHaveBeenCalled()
      expect(mocks.upload).toHaveBeenCalledTimes(3) // report files + history file
    })

    it('copies all report files to latest directory', async () => {
      expect(mocks.copy).toHaveBeenCalled()
      expect(mocks.copy).toHaveBeenCalledTimes(2) // only report files
    })
  })
})
