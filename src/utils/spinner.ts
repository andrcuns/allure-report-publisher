import yoctoSpinner, {Spinner} from 'yocto-spinner'

import {isCi} from './ci.js'
import {config} from './config.js'
import {chalk, logger} from './logger.js'

function flushDebug(): void {
  if (config.debug) logger.flushDebug()
}

function succeed(spinner: Spinner) {
  const msg = `${spinner.text} ... ${chalk().green('done')}`
  if (spinner.isSpinning) {
    spinner.success(msg)
  } else {
    logger.success(msg)
  }

  flushDebug()
}

function fail(spinner: Spinner, error: Error) {
  const msg = `${spinner.text} ... ${chalk().red('failed')}`
  if (spinner.isSpinning) {
    spinner.error(msg)
  } else {
    console.log(`${chalk().red('✖')} ${msg}`)
  }

  flushDebug()
  throw error
}

function warn(spinner: Spinner, error: Error): undefined {
  const msg = `${spinner.text} ... ${chalk().yellow('warning')}`
  if (spinner.isSpinning) {
    spinner.warning(msg)
  } else {
    console.log(`${chalk().yellow('⚠')} ${msg}`)
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
  // Disable spinner by default on CI environments
  const silent = isCi || process.stdout.isTTY === false
  const spinner = yoctoSpinner({text: message})
  if (!silent) spinner.start()

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
