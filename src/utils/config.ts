class Config {
  private _color: boolean
  private _debug: boolean
  private _parallel: number
  private initialized: boolean

  constructor() {
    this._color = process.stdout.isTTY
    this._debug = false
    this._parallel = 8
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

  public get parallel(): number {
    return this._parallel
  }

  public set parallel(value: number) {
    this._parallel = value;
  }

  public initialize(options: {color?: boolean; debug?: boolean; parallel?: number}): void {
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

    this.initialized = true
  }
}

export const config = new Config()
