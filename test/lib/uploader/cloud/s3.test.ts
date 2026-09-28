import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest'

import {S3Uploader} from '../../../../src/lib/uploader/cloud/s3.js'

const mocks = vi.hoisted(() => ({
  send: vi.fn<(...args: unknown[]) => Promise<unknown>>(),
  waitUntilObjectExists: vi.fn<(...args: unknown[]) => Promise<void>>(),
  lookup: vi.fn<(file: string) => string | false>(),
}))

vi.mock('@aws-sdk/client-s3', () => ({
  S3Client: class {
    send = mocks.send
  },
  GetObjectCommand: class {},
  PutObjectCommand: class {},
  CopyObjectCommand: class {},
  NoSuchKey: class {},
  waitUntilObjectExists: mocks.waitUntilObjectExists,
}))

vi.mock('mime-types', () => ({lookup: mocks.lookup}))

describe('S3Uploader', () => {
  let tempDir: string
  let reportDir: string
  let historyFile: string

  let uploader: S3Uploader
  let originalEnv: NodeJS.ProcessEnv

  beforeEach(() => {
    vi.resetAllMocks()
    mocks.send.mockResolvedValue({Body: {transformToString: async () => '{"uuid":"test-uuid-123"}'}})
    mocks.waitUntilObjectExists.mockResolvedValue(undefined)
    mocks.lookup.mockReturnValue('text/html')
    originalEnv = {...process.env}
    delete process.env.GITHUB_RUN_ID

    tempDir = join(tmpdir(), `s3-test-${Date.now()}`)
    reportDir = join(tempDir, 'report')
    historyFile = join(tempDir, 'history.jsonl')

    mkdirSync(reportDir, {recursive: true})
    writeFileSync(historyFile, JSON.stringify({uuid: 'test-uuid-123'}))
    writeFileSync(join(reportDir, 'index.html'), '<html></html>')
    writeFileSync(join(reportDir, 'data.json'), '{}')
  })

  afterEach(() => {
    process.env = originalEnv
    rmSync(tempDir, {force: true, recursive: true})
  })

  describe('reportUrlBase()', () => {
    it('constructs URL from bucket and prefix', () => {
      uploader = new S3Uploader({
        bucket: 'test-bucket',
        copyLatest: true,
        historyPath: historyFile,
        output: reportDir,
        parallel: 2,
        plugins: ['awesome'],
        prefix: 'reports',
      })
      const urlBase = uploader.reportUrlBase()
      expect(urlBase).to.equal('https://test-bucket.s3.us-east-1.amazonaws.com/reports')
    })

    it('uses custom base URL when provided', () => {
      uploader = new S3Uploader({
        bucket: 'test-bucket',
        copyLatest: false,
        historyPath: historyFile,
        output: reportDir,
        parallel: 1,
        plugins: ['awesome'],
        baseUrl: 'https://custom.domain.com',
        prefix: 'reports',
      })
      const urlBase = uploader.reportUrlBase()
      expect(urlBase).to.equal('https://custom.domain.com/reports')
    })

    it('constructs URL without prefix when not provided', () => {
      uploader = new S3Uploader({
        bucket: 'test-bucket',
        copyLatest: false,
        historyPath: historyFile,
        output: reportDir,
        parallel: 1,
        plugins: ['awesome'],
      })
      const urlBase = uploader.reportUrlBase()
      expect(urlBase).to.equal('https://test-bucket.s3.us-east-1.amazonaws.com')
    })
  })
})
