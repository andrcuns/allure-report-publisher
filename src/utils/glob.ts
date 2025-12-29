import {glob} from 'glob'

import {logger} from './logger.js'

export async function getAllureResultsPaths(pattern: string): Promise<string[]> {
  const paths = await glob(pattern, {
    absolute: true,
    nodir: false,
    windowsPathsNoEscape: true,
  })

  logger.debug(`Glob '${pattern}' found ${paths.length} entries`)
  for (const path of paths) {
    logger.debug(`  - ${path}`)
  }

  if (paths.length === 0) {
    throw new Error(
      `No allure results found matching pattern: ${pattern}\n` +
        'Make sure the pattern is correct and points to directories containing allure results.\n' +
        'Use --ignore-missing-results to skip this check.',
    )
  }

  return paths
}
