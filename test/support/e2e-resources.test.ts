import {rmSync} from 'node:fs'
import type * as nodeFs from 'node:fs'
import {beforeEach, describe, expect, it, vi} from 'vitest'

import {cleanupE2eResources} from './e2e-resources.js'
import type {E2eResources} from './e2e-resources.js'

vi.mock('node:fs', async (importOriginal) => ({
  ...(await importOriginal<typeof nodeFs>()),
  rmSync: vi.fn(),
}))

beforeEach(() => {
  vi.mocked(rmSync).mockReset()
})

describe('E2E resource cleanup', () => {
  it('does nothing when startup acquired no resources', async () => {
    const environment = process.env
    await cleanupE2eResources({})
    expect(rmSync).not.toHaveBeenCalled()
    // Keep environment values out of Allure matcher descriptions and failure output.
    expect(process.env === environment).toBe(true)
  })

  it('stops the container, removes fixtures, and restores the environment', async () => {
    const stop = vi.fn<() => Promise<unknown>>().mockResolvedValue(undefined)
    const originalEnv = {...process.env}
    const resources: E2eResources = {container: {stop}, fixtureRoot: 'fixture-copy', originalEnv}
    process.env.ALLURE_PUBLISHER_CLEANUP_PROBE = 'changed'
    await cleanupE2eResources(resources)
    expect(stop).toHaveBeenCalledTimes(1)
    expect(rmSync).toHaveBeenCalledWith('fixture-copy', {recursive: true, force: true})
    expect(resources.container).toBeUndefined()
    expect(process.env === originalEnv).toBe(true)
  })

  it('removes fixtures and restores the environment when stop rejects', async () => {
    const failure = new Error('stop failed')
    const stop = vi.fn<() => Promise<unknown>>().mockRejectedValue(failure)
    const originalEnv = {...process.env}
    const resources: E2eResources = {container: {stop}, fixtureRoot: 'fixture-copy', originalEnv}
    process.env.ALLURE_PUBLISHER_CLEANUP_PROBE = 'changed'
    await expect(cleanupE2eResources(resources)).rejects.toBe(failure)
    expect(rmSync).toHaveBeenCalledWith('fixture-copy', {recursive: true, force: true})
    expect(resources.container).toBeUndefined()
    expect(process.env === originalEnv).toBe(true)
  })

  it('restores the environment when fixture removal throws', async () => {
    const failure = new Error('remove failed')
    vi.mocked(rmSync).mockImplementation(() => {
      throw failure
    })
    const originalEnv = {...process.env}
    process.env.ALLURE_PUBLISHER_CLEANUP_PROBE = 'changed'
    await expect(cleanupE2eResources({fixtureRoot: 'fixture-copy', originalEnv})).rejects.toBe(failure)
    expect(process.env === originalEnv).toBe(true)
  })
})
