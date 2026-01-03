// eslint-disable-next-line unicorn/import-style
import {Chalk} from 'chalk'

import {config} from './config.js'

export const chalk = new Chalk({level: config.color ? 3 : 0})

export class Logger {
  private debugBuffer: string[] = []

  flushDebug(): void {
    if (this.debugBuffer.length === 0) return

    console.log(chalk.gray('====== DEBUG LOG OUTPUT ======'))
    for (const message of this.debugBuffer) {
      console.log(chalk.gray(message))
    }

    console.log(chalk.gray('====== DEBUG LOG OUTPUT ======'))
    this.debugBuffer = []
  }

  debug(message: string): void {
    const timestamp = new Date().toISOString()
    this.debugBuffer.push(`[${timestamp}] ${message}`)
  }

  error(message: string): void {
    console.error(chalk.red(message))
  }

  info(message: string): void {
    console.log(chalk.blue('ℹ'), message)
  }

  log(message: string): void {
    console.log(message)
  }

  success(message: string): void {
    console.log(chalk.green('✓'), message)
  }

  warn(message: string): void {
    console.warn(chalk.yellow(message))
  }

  section(message: string): void {
    if (config.color) {
      console.log(chalk.bold.magenta(`\n${message}`))
    } else {
      console.log(`\n=== ${message} ===`)
    }
  }
}

export const logger = new Logger()
