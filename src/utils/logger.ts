// eslint-disable-next-line unicorn/import-style
import {Chalk, ChalkInstance} from 'chalk'
import supportsColor, { ColorSupport } from 'supports-color'

import {config} from './config.js'

let _chalk: ChalkInstance | undefined

export const chalk = () => {
  if (!_chalk) {
    const {level} = (supportsColor.stdout as ColorSupport)
    _chalk = new Chalk({level: config.color ? level : 0})
  }

  return _chalk
}

export class Logger {
  private debugBuffer: string[] = []

  private get chalk() {
    return chalk()
  }

  flushDebug(): void {
    if (this.debugBuffer.length === 0) return

    console.log(this.chalk.gray('====== DEBUG LOG OUTPUT ======'))
    for (const message of this.debugBuffer) {
      console.log(this.chalk.gray(message))
    }

    console.log(this.chalk.gray('====== DEBUG LOG OUTPUT ======'))
    this.debugBuffer = []
  }

  debug(message: string): void {
    const timestamp = new Date().toISOString()
    this.debugBuffer.push(`[${timestamp}] ${message}`)
  }

  error(message: string): void {
    console.error(this.chalk.red(message))
  }

  info(message: string): void {
    console.log(this.chalk.blue('ℹ'), message)
  }

  log(message: string): void {
    console.log(message)
  }

  success(message: string): void {
    console.log(this.chalk.green('✓'), message)
  }

  warn(message: string): void {
    console.warn(this.chalk.yellow(message))
  }

  section(message: string): void {
    if (config.color) {
      console.log(this.chalk.bold.magenta(`\n${message}`))
    } else {
      console.log(`\n=== ${message} ===`)
    }
  }
}

export const logger = new Logger()
