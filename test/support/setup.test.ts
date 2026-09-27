import {describe, expect, it, vi} from 'vitest'

import {globalConfig} from '../../src/utils/global-config.js'

const key = 'ALLURE_PUBLISHER_SETUP_PROBE'
const originalValue = process.env[key]
const target = {value: () => 42}

describe('shared Vitest setup', () => {
  it('allows a case to mutate environment and a spy', () => {
    process.env[key] = 'temporary'
    vi.spyOn(target, 'value').mockReturnValue(0)
    expect(process.env[key]).toBe('temporary')
    expect(target.value()).toBe(0)
  })

  it('restores environment and spies before the next case', () => {
    expect(process.env[key]).toBe(originalValue)
    expect(target.value()).toBe(42)
  })

  it('initializes the unit logging configuration', () => {
    expect(process.env.E2E_TEST).toBe('false')
    expect(globalConfig.disableOutput).toBe(true)
    expect(globalConfig.debug).toBe(true)
  })
})
