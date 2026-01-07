import {mkdirSync, readFileSync, writeFileSync} from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import {pathToFileURL} from 'node:url'
import yaml from 'yaml'

import {PluginName} from '../../types/index.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'

type ConfigObject = {
  appendHistory?: boolean
  historyPath?: string
  name?: string
  output?: string
  plugins?: Record<string, Plugin>
}

type Plugin = {
  enabled?: boolean
  import?: string
  options?: Record<string, boolean | number | string>
}

export interface AllureConfig {
  configPath(): string
  historyPath(): Promise<string>
  outputPath(): Promise<string>
  plugins(): Promise<PluginName[]>
  resultsGlob: string
}

// In CI environments, use relative paths within build dir
const defaultGlobPattern = './**/allure-results'

class CustomConfig implements AllureConfig {
  private _configPath: string
  private _defaultConfig: ConfigObject
  private _parsedConfig: ConfigObject | undefined
  public resultsGlob: string

  constructor(configPath: string, resultsGlob: string) {
    this._configPath = configPath
    this.resultsGlob = resultsGlob
    this._defaultConfig = new DefaultConfig(resultsGlob).config
  }

  public configPath() {
    return this._configPath
  }

  public async historyPath() {
    const config = await this.customConfig()
    const path = config.historyPath
    if (!path) throw new Error('History path is not defined in the allure config')

    return path
  }

  public async outputPath() {
    const config = await this.customConfig()
    return config.output || this._defaultConfig.output!
  }

  public async plugins() {
    const config = await this.customConfig()
    const plugins: Set<PluginName> = new Set(['allure2', 'awesome', 'classic', 'csv', 'dashboard'])
    const configPlugins = config.plugins || this._defaultConfig.plugins!

    return Object.entries(configPlugins)
      .filter(([pluginName, config]) => plugins.has(pluginName as PluginName) && (config.enabled ?? true))
      .map(([pluginName]) => pluginName as PluginName)
  }

  private async customConfig(): Promise<ConfigObject> {
    if (this._parsedConfig === undefined) {
      this._parsedConfig = await spin(this.loadConfig(), 'loading custom allure config')
    }

    return this._parsedConfig!
  }

  private async loadConfig(): Promise<ConfigObject> {
    const ext = path.extname(this._configPath).toLowerCase()
    switch (ext) {
      case '.cjs':
      case '.js':
      case '.mjs': {
        const fileUrl = pathToFileURL(this._configPath).href
        const module = await import(fileUrl)
        // module.default will contain the object returned by defineConfig()
        // allure loads parser with default config setup which will create error in the output
        // plain object should be exported to avoid that
        const defaultConfig = module.default
        if (defaultConfig === undefined) {
          throw new Error(`No default export found in the config file: ${this._configPath}`)
        }

        // Log plain file as dynamic js import may contain functions etc.
        logger.debug(`Loaded JS config:\n${readFileSync(this._configPath, 'utf8')}`)

        return defaultConfig
      }

      case '.json': {
        const content = JSON.parse(readFileSync(this._configPath, 'utf8'))
        logger.debug(`Loaded JSON config: ${JSON.stringify(content, null, 2)}`)
        return content
      }

      case '.yaml': {
        const content = yaml.parse(readFileSync(this._configPath, 'utf8'))
        logger.debug(`Loaded YAML config: ${JSON.stringify(content, null, 2)}`)
        return content
      }

      default: {
        throw new Error(`Unsupported config file format: ${ext}`)
      }
    }
  }
}
class DefaultConfig implements AllureConfig {
  private _configPath: string
  private _configCreated: boolean
  private _baseDir: string
  private _output: string
  private reportName: string | undefined
  public resultsGlob: string

  constructor(resultsGlob?: string, reportName?: string, output?: string, baseDir?: string) {
    this._configCreated = false
    this._baseDir = baseDir ?? path.join(os.tmpdir(), 'allure-report-publisher')
    this._output = output ?? path.join(this._baseDir, 'allure-report')
    this._configPath = path.join(this._baseDir, 'allurerc.json')
    this.reportName = reportName
    this.resultsGlob = resultsGlob || defaultGlobPattern
  }

  public configPath() {
    if (this._configCreated) return this._configPath

    mkdirSync(this._baseDir, {recursive: true})
    writeFileSync(this._configPath, JSON.stringify(this.config, null, 2))
    this._configCreated = true

    return this._configPath
  }

  public get config() {
    return {
      output: this._output,
      historyPath: path.join(this._baseDir, 'history.jsonl'),
      appendHistory: true,
      plugins: {
        awesome: {
          options: {
            enabled: true,
            singleFile: true,
            reportName: this.reportName ?? 'Test Report',
          },
        },
      },
    }
  }

  public async plugins() {
    return ['awesome'] as PluginName[]
  }

  public async historyPath() {
    return this.config.historyPath
  }

  public async outputPath() {
    return this._output
  }
}

export function getAllureConfig(opts: {
  configPath?: string
  reportName?: string
  resultsGlob?: string
  output?: string
  baseDir?: string
}): AllureConfig {
  if (opts.configPath) return new CustomConfig(opts.configPath, opts.resultsGlob || defaultGlobPattern)

  return new DefaultConfig(opts.resultsGlob || defaultGlobPattern, opts.reportName, opts.output, opts.baseDir)
}
