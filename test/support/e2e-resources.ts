import {rmSync} from 'node:fs'

export type E2eResources = {
  container?: {stop(): Promise<unknown>}
  fixtureRoot?: string
  originalEnv?: NodeJS.ProcessEnv
}

export async function cleanupE2eResources(resources: E2eResources): Promise<void> {
  try {
    if (resources.container) await resources.container.stop()
  } finally {
    resources.container = undefined
    try {
      if (resources.fixtureRoot) rmSync(resources.fixtureRoot, {recursive: true, force: true})
    } finally {
      if (resources.originalEnv) process.env = resources.originalEnv
    }
  }
}
