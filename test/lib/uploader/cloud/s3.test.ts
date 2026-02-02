/* eslint-disable @typescript-eslint/no-explicit-any */
import esmock from 'esmock'
import { mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import * as sinon from 'sinon'

import { S3Uploader } from '../../../../src/lib/uploader/cloud/s3.js'
import { expect } from '../../../support/setup.js'

describe('S3Uploader', () => {
    let tempDir: string
    let reportDir: string
    let historyFile: string

    let s3ClientStub: any
    let sendStub: any
    let Uploader: typeof S3Uploader
    let uploader: S3Uploader
    let originalEnv: NodeJS.ProcessEnv

    beforeEach(async () => {
        originalEnv = { ...process.env }
        delete process.env.GITHUB_RUN_ID

        tempDir = join(tmpdir(), `s3-test-${Date.now()}`)
        reportDir = join(tempDir, 'report')
        historyFile = join(tempDir, 'history.jsonl')

        mkdirSync(reportDir, { recursive: true })
        writeFileSync(historyFile, JSON.stringify({ uuid: 'test-uuid-123' }))
        writeFileSync(join(reportDir, 'index.html'), '<html></html>')
        writeFileSync(join(reportDir, 'data.json'), '{}')

        sendStub = sinon.stub().resolves({ Body: { transformToString: async () => '{"uuid":"test-uuid-123"}' } })
        s3ClientStub = sinon.stub().returns({ send: sendStub })

        const module = await esmock('../../../../src/lib/uploader/cloud/s3.js', {
            '@aws-sdk/client-s3': {
                S3Client: s3ClientStub,
                GetObjectCommand: sinon.stub(),
                PutObjectCommand: sinon.stub(),
                CopyObjectCommand: sinon.stub(),
                waitUntilObjectExists: sinon.stub().resolves(),
                NoSuchKey: class { },
            },
            'mime-types': {
                lookup: sinon.stub().returns('text/html'),
            },
        })

        Uploader = module.S3Uploader
    })

    afterEach(() => {
        process.env = originalEnv
        rmSync(tempDir, { force: true, recursive: true })
    })

    describe('reportUrlBase()', () => {

        it('constructs URL from bucket and prefix', () => {
            uploader = new Uploader({
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
            uploader = new Uploader({
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
            uploader = new Uploader({
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
