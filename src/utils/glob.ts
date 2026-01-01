import {glob} from 'glob'
import {statSync} from 'node:fs'

import {logger} from './logger.js'

export async function globPaths(pattern: string, opts: {nodir?: boolean} = {}) {
  return glob(pattern, {
    absolute: true,
    nodir: opts.nodir ?? false,
    windowsPathsNoEscape: true,
  })
}

export async function getAllureResultsPaths(pattern: string, ignoreMissing?: boolean): Promise<string[]> {
  const paths = await globPaths(pattern)

  logger.debug(`Glob '${pattern}' found ${paths.length} entries`)
  for (const path of paths) {
    logger.debug(`- ${path}`)
  }

  if (paths.length === 0) {
    const msg = [
      `Pattern '${pattern}' did not match any paths`,
      'Make sure the pattern is correct and points to directories containing allure results',
    ]
    if (!ignoreMissing) msg.push('Use --ignore-missing-results to exit without error if no result paths are found')
    throw new Error(msg.join('\n'))
  }

  const nonDirectories = paths.filter((path) => !statSync(path).isDirectory())
  if (nonDirectories.length > 0) {
    const msg = [
      `Pattern '${pattern}' matched ${nonDirectories.length} non-directory paths`,
      'All matched paths must be directories containing allure results',
    ]
    throw new Error(msg.join('\n'))
  }

  return paths
}
