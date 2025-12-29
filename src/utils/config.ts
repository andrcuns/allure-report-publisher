class Config {
  private _color: boolean
  private _debug: boolean
  private initialized: boolean

  constructor() {
    this._color = true
    this._debug = false
    this.initialized = false
  }

  public get color(): boolean {
    if (!this.initialized) console.warn("Config has not been initialized yet, returning default value")
    return this._color
  }

  public get debug(): boolean {
    if (!this.initialized) console.warn("Config has not been initialized yet, returning default value")
    return this._debug
  }

  public initialize(options: {color?: boolean; debug?: boolean}): void {
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

export const config = new Config()
