import {mkdirSync, readFileSync, writeFileSync} from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import {pathToFileURL} from 'node:url'
import yaml from 'yaml'

import {PluginName} from '../../types/index.js'
import {logger} from '../../utils/logger.js'
import {spin} from '../../utils/spinner.js'
import {isCI} from '../ci/utils.js'

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
const defaultReportBasePath = path.join(isCI ? './' : os.tmpdir(), 'allure-report-publisher')
const defaultConfig: ConfigObject = {
  output: path.join(defaultReportBasePath, 'allure-report'),
  historyPath: path.join(defaultReportBasePath, 'history.jsonl'),
  appendHistory: true,
  plugins: {
    awesome: {
      options: {
        enabled: true,
        singleFile: true,
        reportName: 'Test Report',
      },
    },
  },
}

class CustomConfig implements AllureConfig {
  private _configPath: string
  private _parsedConfig: ConfigObject | Promise<ConfigObject> = defaultConfig
  public resultsGlob: string

  constructor(configPath: string, resultsGlob: string) {
    this._configPath = configPath
    this.resultsGlob = resultsGlob
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
    return config.output || defaultConfig.output!
  }

  public async plugins() {
    const config = await this.customConfig()
    const plugins: Set<PluginName> = new Set(['allure2', 'awesome', 'classic', 'csv', 'dashboard'])
    const configPlugins = config?.plugins || defaultConfig.plugins!

    return Object.entries(configPlugins)
      .filter(([pluginName, config]) => plugins.has(pluginName as PluginName) && (config.enabled ?? true))
      .map(([pluginName]) => pluginName as PluginName)
  }

  private async customConfig() {
    if (this._parsedConfig === defaultConfig) {
      this._parsedConfig = await spin(this.loadConfig(), 'loading custom allure config')
    }

    return this._parsedConfig
  }

  private async loadConfig() {
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

        logger.debug(`Loaded JS config: ${JSON.stringify(defaultConfig, null, 2)}`)

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
  private _configCreated: boolean
  private _configPath: string
  private reportName: string | undefined
  public resultsGlob: string

  constructor(resultsGlob: string, reportName?: string) {
    this._configCreated = false
    this._configPath = path.join(defaultReportBasePath, 'allurerc.json')
    this.reportName = reportName
    this.resultsGlob = resultsGlob
  }

  public configPath() {
    if (this._configCreated) return this._configPath

    mkdirSync(defaultReportBasePath, {recursive: true})
    const config = {...defaultConfig}
    if (this.reportName) config.plugins!.awesome!.options!.reportName = this.reportName
    writeFileSync(this._configPath, JSON.stringify(config, null, 2))
    this._configCreated = true

    return this._configPath
  }

  public async plugins() {
    return ['awesome'] as PluginName[]
  }

  public async historyPath() {
    return defaultConfig.historyPath!
  }

  public async outputPath() {
    return defaultConfig.output!
  }
}

export function getAllureConfig(opts: {configPath?: string; reportName?: string; resultsGlob?: string}): AllureConfig {
  if (opts.configPath) return new CustomConfig(opts.configPath, opts.resultsGlob || defaultGlobPattern)

  return new DefaultConfig(opts.resultsGlob || defaultGlobPattern, opts.reportName)
}
