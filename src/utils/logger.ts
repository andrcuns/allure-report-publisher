// eslint-disable-next-line unicorn/import-style
import {Chalk, ChalkInstance} from 'chalk'

import {globalConfig} from './global-config.js'

let _chalk: ChalkInstance | undefined

export const chalk = () => {
  if (!_chalk) {
    _chalk = new Chalk({level: globalConfig.colorLevel})
  }

  return _chalk
}

export const resetChalk = () => {
  _chalk = undefined
}

export class Logger {
  private debugBuffer: string[] = []

  private get chalk() {
    return chalk()
  }

  flushDebug(): void {
    if (globalConfig.disableOutput) return
    if (this.debugBuffer.length === 0) return

    console.log(this.chalk.gray('====== DEBUG LOG OUTPUT ======'))
    for (const message of this.debugBuffer) {
      console.log(this.chalk.gray(message))
    }

    console.log(this.chalk.gray('====== DEBUG LOG OUTPUT ======'))
    this.debugBuffer = []
  }

  debug(message: string): void {
    if (globalConfig.disableOutput) return

    const timestamp = new Date().toISOString()
    this.debugBuffer.push(`[${timestamp}] ${message}`)
  }

  error(message: string): void {
    if (globalConfig.disableOutput) return

    console.error(this.chalk.red(message))
  }

  info(message: string): void {
    if (globalConfig.disableOutput) return

    console.log(this.chalk.blue('ℹ'), message)
  }

  log(message: string): void {
    if (globalConfig.disableOutput) return

    console.log(message)
  }

  success(message: string): void {
    if (globalConfig.disableOutput) return

    console.log(this.chalk.green('✓'), message)
  }

  warn(message: string): void {
    if (globalConfig.disableOutput) return

    console.warn(this.chalk.yellow(message))
  }

  section(message: string): void {
    if (globalConfig.disableOutput) return

    if (this.chalk.level > 0) {
      console.log(this.chalk.bold.magenta(`\n${message}`))
    } else {
      console.log(`\n=== ${message} ===`)
    }
  }
}

export const logger = new Logger()
