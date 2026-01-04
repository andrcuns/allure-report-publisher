import {glob, globSync} from 'glob'
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
  const ignoreMention = 'Use --ignore-missing-results to exit without error if no result paths are found'
  const raiseError = (msg: string[]) => {
    if (!ignoreMissing) msg.push(ignoreMention)
    throw new Error(msg.join('\n'))
  }

  logger.debug(`Glob '${pattern}' found ${paths.length} entries`)
  for (const path of paths) {
    logger.debug(`- ${path}`)
  }

  if (paths.length === 0) {
    const msg = [
      `Pattern '${pattern}' did not match any paths`,
      'Make sure the pattern is correct and points to directories containing allure results',
    ]
    raiseError(msg)
  }

  const nonDirectories = paths.filter((path) => !statSync(path).isDirectory())
  if (nonDirectories.length > 0) {
    const msg = [
      `Pattern '${pattern}' matched ${nonDirectories.length} non-directory paths`,
      'All matched paths must be directories containing allure results',
    ]
    raiseError(msg)
  }

  const containsResults = paths.some((path) => globSync(`${path}/*.json`, {nodir: true}).length > 0)
  if (!containsResults) {
    const msg = [
      `No allure results found in the matched directories for pattern '${pattern}'`,
      'Make sure the directories contain valid allure result files (*.json)',
    ]
    raiseError(msg)
  }

  return paths
}
