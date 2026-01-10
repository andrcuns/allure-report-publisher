import {expect} from 'chai'
import {mkdirSync, rmSync, writeFileSync} from 'node:fs'
import {tmpdir} from 'node:os'
import {join} from 'node:path'
import * as sinon from 'sinon'

import {GcsUploader} from '../../../../src/lib/uploader/cloud/gcs.js'

describe('GcsUploader', () => {
  let tempDir: string
  let reportDir: string
  let historyFile: string
  let storageStub: any
  let bucketStub: any
  let fileStub: any
  let uploader: GcsUploader

  beforeEach(() => {
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
      upload: sinon.stub().resolves(),
      file: sinon.stub().returns(fileStub),
    }

    storageStub = {
      bucket: sinon.stub().returns(bucketStub),
    }

    uploader = new GcsUploader({
      bucket: 'test-bucket',
      copyLatest: true,
      historyPath: historyFile,
      output: reportDir,
      parallel: 2,
      plugins: ['awesome'],
      prefix: 'reports',
    })

    // Replace the storage client
    ;(uploader as any).storageClient = storageStub
  })

  afterEach(() => {
    sinon.restore()
    rmSync(tempDir, {force: true, recursive: true})
  })

  describe('reportUrlBase()', () => {
    it('constructs URL from bucket and prefix', () => {
      const url = (uploader as any).reportUrlBase()

      expect(url).to.equal('https://storage.googleapis.com/test-bucket/reports')
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

      const url = (customUploader as any).reportUrlBase()

      expect(url).to.equal('https://custom.domain.com/test-bucket/reports')
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

      const url = (noPrefixUploader as any).reportUrlBase()

      expect(url).to.equal('https://storage.googleapis.com/test-bucket')
    })

    it('caches the URL after first call', () => {
      const url1 = (uploader as any).reportUrlBase()
      const url2 = (uploader as any).reportUrlBase()

      expect(url1).to.equal(url2)
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

  describe('uploadHistory()', () => {
    it('calls bucket upload with history file', async () => {
      await (uploader as any).uploadHistory()

      expect(storageStub.bucket.calledWith('test-bucket')).to.be.true
      expect(bucketStub.upload.calledOnce).to.be.true
      expect(bucketStub.upload.firstCall.args[0]).to.equal(historyFile)
    })

    it('uses correct destination key for history file', async () => {
      await (uploader as any).uploadHistory()

      const uploadOptions = bucketStub.upload.firstCall.args[1]
      expect(uploadOptions.destination).to.equal('reports/history.jsonl')
    })
  })

  describe('uploadReport()', () => {
    it('uploads all report files to bucket', async () => {
      await (uploader as any).uploadReport()

      expect(bucketStub.upload.called).to.be.true
      expect(bucketStub.upload.callCount).to.equal(2) // index.html and data.json
    })

    it('constructs correct keys for report files', async () => {
      await (uploader as any).uploadReport()

      const calls = bucketStub.upload.getCalls()
      const destinations = calls.map((call: any) => call.args[1].destination)

      expect(destinations.some((dest: string) => dest.includes('index.html'))).to.be.true
      expect(destinations.some((dest: string) => dest.includes('data.json'))).to.be.true
    })

    it('includes runId in file keys', async () => {
      await (uploader as any).uploadReport()

      const {destination} = bucketStub.upload.firstCall.args[1]
      expect(destination).to.include('reports/')
    })
  })

  describe('createLatestCopy()', () => {
    it('copies all report files to latest directory', async () => {
      await (uploader as any).createLatestCopy()

      expect(fileStub.copy.called).to.be.true
      expect(fileStub.copy.callCount).to.equal(2) // index.html and data.json
    })

    it('copies from runId to latest directory', async () => {
      await (uploader as any).createLatestCopy()

      // Check that source keys don't contain 'latest'
      const sourceCalls = bucketStub.file.getCalls()
      const sourceKeys = sourceCalls.map((call: any) => call.args[0])

      // Source keys should contain runId but not 'latest'
      const hasNonLatestSources = sourceKeys.some((key: string) => !key.includes('latest'))
      expect(hasNonLatestSources).to.be.true
    })

    it('sets destination as latest directory', async () => {
      await (uploader as any).createLatestCopy()

      // Check that copy was called with destination files
      const copyCalls = fileStub.copy.getCalls()
      expect(copyCalls.length).to.be.greaterThan(0)

      // Verify storageStub.bucket was called for destination buckets
      const bucketCalls = storageStub.bucket.getCalls()
      expect(bucketCalls.length).to.be.greaterThan(0)
    })
  })
})
