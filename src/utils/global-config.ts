import os from 'node:os'
import path from 'node:path'
import supportsColor, {ColorSupport} from 'supports-color'

class GlobalConfig {
  private _color: boolean
  private _debug: boolean
  private _parallel: number
  private _baseDir: string
  private _output: string
  private initialized: boolean

  constructor() {
    this._color = (supportsColor.stdout as ColorSupport).hasBasic
    this._debug = false
    this._parallel = 8
    this._baseDir = path.join(os.tmpdir(), 'allure-report-publisher')
    this._output = path.join(this._baseDir, 'allure-report')
    this.initialized = false
  }

  public get debug(): boolean {
    if (!this.initialized) console.warn('Config has not been initialized yet, returning default value')
    return this._debug
  }

  public get color(): boolean {
    return this._color
  }

  public get parallel(): number {
    return this._parallel
  }

  public set parallel(value: number) {
    this._parallel = value
  }

  public get baseDir(): string {
    return this._baseDir
  }

  public get output(): string {
    return this._output
  }

  public initialize(options: {
    color?: boolean
    debug?: boolean
    parallel?: number
    baseDir?: string
    output?: string
  }): void {
    if (this.initialized) {
      throw new Error('Config has already been initialized')
    }

    if (options.color !== undefined) {
      this._color = options.color
    }

    if (options.debug !== undefined) {
      this._debug = options.debug
    }

    if (options.parallel !== undefined) {
      this._parallel = options.parallel
    }

    if (options.baseDir !== undefined) {
      this._baseDir = options.baseDir
    }

    if (options.output !== undefined) {
      this._output = options.output
    }

    this.initialized = true
  }
}

export const globalConfig = new GlobalConfig()
