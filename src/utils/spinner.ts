import chalk from 'chalk'
import ora, { Options } from 'ora'

import {config} from './config.js'
import {logger} from './logger.js'

function flushDebug(): void {
  if (config.debug) logger.flushDebug()
}

export async function spin<T>(
  action: PromiseLike<T>,
  message: string,
  options: Options & {ignoreError?: boolean} = {},
): Promise<T | undefined> {
  const spinner = ora(message).start()

  try {
    const result = await action
    spinner.succeed(`${message} ... ${chalk.green('done')}`)
    flushDebug()

    return result
  } catch (error) {
    if (options.ignoreError) {
      spinner.warn(`${message} ... ${chalk.yellow('failed')}`)
      flushDebug()
      return undefined
    }

    spinner.fail(`${message} ... ${chalk.red('failed')}`)
    flushDebug()
    throw error
  }
}
