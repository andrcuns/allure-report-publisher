/* eslint-disable @typescript-eslint/no-explicit-any */
import esmock from 'esmock'
import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import * as sinon from 'sinon'

import {GcsUploader} from '../../../../src/lib/uploader/cloud/gcs.js'
import {expect} from '../../../support/setup.js'

describe('GcsUploader', () => {
  let tempDir: string
  let reportDir: string
  let historyFile: string

  let fileStub: any
  let bucketStub: any
  let storageStub: any

  let Uploader: typeof GcsUploader
  let uploader: GcsUploader

  let originalEnv: NodeJS.ProcessEnv

  beforeEach(async () => {
    originalEnv = {...process.env}
    delete process.env.GITHUB_RUN_ID

    tempDir = join(tmpdir(), `gcs-test-${Date.now()}`)
    reportDir = join(tempDir, 'report')
    historyFile = join(tempDir, 'history.jsonl')

    mkdirSync(reportDir, {recursive: true})
    writeFileSync(historyFile, JSON.stringify({uuid: 'test-uuid-123'}))
    writeFileSync(join(reportDir, 'index.html'), '<html></html>')
    writeFileSync(join(reportDir, 'data.json'), '{}')

    fileStub = {
      download: sinon.stub().resolves(),
      copy: sinon.stub().resolves(),
    }
    bucketStub = {
      file: sinon.stub().returns(fileStub),
      upload: sinon.stub().resolves(),
    }
    storageStub = {
      bucket: sinon.stub().returns(bucketStub),
    }

    const module = await esmock('../../../../src/lib/uploader/cloud/gcs.js', {
      '@google-cloud/storage': {
        Storage: sinon.stub().returns(storageStub),
      },
    })

    Uploader = module.GcsUploader

    uploader = new Uploader({
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
      const customUploader = new Uploader({
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
      const noPrefixUploader = new Uploader({
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

      expect(storageStub.bucket.calledWith('test-bucket')).to.be.true
      expect(bucketStub.file.calledOnce).to.be.true
      expect(fileStub.download.calledOnce).to.be.true
      expect(fileStub.download.firstCall.args[0]).to.deep.include({
        destination: historyFile,
      })
    })

    it('constructs history file key with prefix', async () => {
      await uploader.downloadHistory()

      const fileKey = bucketStub.file.firstCall.args[0]
      expect(fileKey).to.equal('reports/history.jsonl')
    })
  })

  describe('upload()', () => {
    beforeEach(async () => {
      await uploader.upload()
    })

    it('calls bucket upload with history file', async () => {
      expect(storageStub.bucket.calledWith('test-bucket')).to.be.true
      expect(bucketStub.upload.firstCall.args[0]).to.equal(historyFile)
    })

    it('uses correct destination key for history file', async () => {
      const uploadOptions = bucketStub.upload.firstCall.args[1]
      expect(uploadOptions.destination).to.equal('reports/history.jsonl')
    })

    it('uploads all report files to bucket', async () => {
      expect(bucketStub.upload.called).to.be.true
      expect(bucketStub.upload.callCount).to.equal(3) // report files + history file
    })

    it('copies all report files to latest directory', async () => {
      expect(fileStub.copy.called).to.be.true
      expect(fileStub.copy.callCount).to.equal(2) // only report files
    })
  })
})
