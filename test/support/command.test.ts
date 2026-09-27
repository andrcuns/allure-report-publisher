import {Config, settings} from '@oclif/core'
import {describe, expect, it, vi} from 'vitest'

import {captureCommand, runCommand} from './command.js'

const probeKey = 'ALLURE_PUBLISHER_COMMAND_CAPTURE_PROBE'

describe('command support', () => {
  it('captures both streams and runs write callbacks', async () => {
    const callback = vi.fn()
    const result = await captureCommand(async () => {
      process.stdout.write('first', callback)
      process.stdout.write(Buffer.from(' second'), 'utf8')
      process.stderr.write('warning', 'utf8', callback)
      console.log(' console output')
      console.error(' console error')
    })
    expect(result).toEqual({stdout: 'first second console output\n', stderr: 'warning console error\n'})
    expect(callback).toHaveBeenCalledTimes(2)
  })

  it('restores streams, environment, and exit state after success', async () => {
    const stdout = process.stdout.write
    const stderr = process.stderr.write
    const value = process.env[probeKey]
    const {exitCode} = process
    await captureCommand(async () => {
      process.env[probeKey] = 'changed'
      process.exitCode = 7
    })
    expect(process.stdout.write).toBe(stdout)
    expect(process.stderr.write).toBe(stderr)
    expect(process.env[probeKey]).toBe(value)
    expect(process.exitCode).toBe(exitCode)
  })

  it('preserves Error identity and restores state after failure', async () => {
    const failure = new Error('command failed')
    const stdout = process.stdout.write
    const stderr = process.stderr.write
    const value = process.env[probeKey]
    const {exitCode} = process
    const result = await captureCommand(async () => {
      process.env[probeKey] = 'changed'
      process.exitCode = 9
      process.stderr.write('before failure')
      throw failure
    })
    expect(result.error).toBe(failure)
    expect(result.stderr).toBe('before failure')
    expect(process.stdout.write).toBe(stdout)
    expect(process.stderr.write).toBe(stderr)
    expect(process.env[probeKey]).toBe(value)
    expect(process.exitCode).toBe(exitCode)
  })

  it('returns a non-Error rejection as an error with its cause', async () => {
    const result = await captureCommand(() => Promise.reject('rejected value'))
    expect(result.error).toBeInstanceOf(Error)
    expect(result.error?.message).toBe('rejected value')
    expect(result.error?.cause).toBe('rejected value')
  })

  it('restores the oclif loader setting when configuration loading fails', async () => {
    const failure = new Error('configuration failed')
    const autoTranspile = settings.enableAutoTranspile
    vi.spyOn(Config, 'load').mockRejectedValue(failure)
    const result = await runCommand(['upload', 's3', '--help'])
    expect(result.error).toBe(failure)
    expect(settings.enableAutoTranspile).toBe(autoTranspile)
  })

  it('executes source command validation without reaching cloud operations', async () => {
    const {BaseCloudUploadCommand} = await import('../../src/lib/commands/upload.js')
    const sourceRun = vi.spyOn(BaseCloudUploadCommand.prototype, 'run')
    const result = await runCommand([
      'upload',
      's3',
      '--bucket=test-bucket',
      '--parallel=0',
      '--results-glob=test/fixtures/allure-results',
    ])
    expect(sourceRun).toHaveBeenCalledTimes(1)
    expect(result.error).toBeInstanceOf(Error)
    expect(result.error?.message).toContain('Invalid parallel threads: 0')
  })
})
