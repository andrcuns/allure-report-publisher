import ora, {Ora} from 'ora'

import {isCi} from './ci.js'
import {config} from './config.js'
import {chalk, logger} from './logger.js'

function flushDebug(): void {
  if (config.debug) logger.flushDebug()
}

function succeed(spinner: Ora) {
  const msg = `${spinner.text} ... ${chalk.green('done')}`
  if (spinner.isSpinning) {
    spinner.succeed(msg)
  } else {
    logger.success(msg)
  }

  flushDebug()
}

function fail(spinner: Ora, error: Error) {
  const msg = `${spinner.text} ... ${chalk.red('failed')}`
  if (spinner.isSpinning) {
    spinner.fail(msg)
  } else {
    console.log(msg)
  }

  flushDebug()
  throw error
}

function warn(spinner: Ora, error: Error): undefined {
  const msg = `${spinner.text} ... ${chalk.yellow('warning')}`
  if (spinner.isSpinning) {
    spinner.warn(msg)
  } else {
    console.log(msg)
  }

  flushDebug()
  logger.warn(error.message)
  return undefined
}

export async function spin<T>(
  action: PromiseLike<T>,
  message: string,
  options: {ignoreError?: boolean} = {},
): Promise<T | undefined> {
  const silent = isCi || process.stdout.isTTY === false
  const spinner = ora({text: message, isSilent: silent, color: config.color}).start()

  try {
    const result = await action
    succeed(spinner)

    return result
  } catch (error) {
    if (options.ignoreError) return warn(spinner, error as Error)

    fail(spinner, error as Error)
    throw error
  }
}
