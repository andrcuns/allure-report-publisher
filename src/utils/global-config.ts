import supportsColor, {ColorSupport} from 'supports-color'

class GlobalConfig {
  private _color: boolean
  private _debug: boolean
  private initialized: boolean

  constructor() {
    this._color = (supportsColor.stdout as ColorSupport).hasBasic
    this._debug = false
    this.initialized = false
  }

  public get debug(): boolean {
    if (!this.initialized) console.warn('Config has not been initialized yet, returning default value')
    return this._debug
  }

  public get color(): boolean {
    return this._color
  }

  public initialize(options: {
    color?: boolean
    debug?: boolean
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

    this.initialized = true
  }
}

export const globalConfig = new GlobalConfig()
