import {afterEach, beforeAll, beforeEach} from 'vitest'

import {globalConfig} from '../../src/utils/global-config.js'

let originalEnv: NodeJS.ProcessEnv

function configureOutput(): void {
  globalConfig.reset()
  globalConfig.initialize({
    disableOutput: process.env.E2E_TEST !== 'true',
    debug: true,
  })
}

beforeAll(configureOutput)

beforeEach(() => {
  originalEnv = {...process.env}
  configureOutput()
})

afterEach(() => {
  process.env = originalEnv
})
