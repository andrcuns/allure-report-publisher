import supportsColor, {ColorSupport, ColorSupportLevel} from 'supports-color'

class GlobalConfig {
  private _colorLevel: ColorSupportLevel
  private _debug: boolean
  private initialized: boolean

  constructor() {
    this._colorLevel = (supportsColor.stdout as ColorSupport).level
    this._debug = false
    this.initialized = false
  }

  public get debug(): boolean {
    if (!this.initialized) console.warn('Config has not been initialized yet, returning default value')
    return this._debug
  }

  public get colorLevel(): ColorSupportLevel {
    return this._colorLevel
  }

  public initialize(options: {
    colorLevel?: ColorSupportLevel
    debug?: boolean
  }): void {
    if (this.initialized) {
      throw new Error('Config has already been initialized')
    }

    if (options.colorLevel !== undefined) {
      this._colorLevel = options.colorLevel
    }

    if (options.debug !== undefined) {
      this._debug = options.debug
    }

    this.initialized = true
  }
}

export const globalConfig = new GlobalConfig()
