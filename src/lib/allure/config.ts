import {mkdirSync, readFileSync, writeFileSync} from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import yaml from 'yaml'

import {PluginName} from '../../types/index.js'
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
}

const defaultReportBasePath = path.join(os.tmpdir(), 'allure-report-publisher')
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

  constructor(configPath: string) {
    this._configPath = configPath
  }

  public configPath() {
    return this._configPath
  }

  public async historyPath() {
    const config = await this.customConfig()
    return config.historyPath || defaultConfig.historyPath!
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
      case '.json': {
        const content = readFileSync(this._configPath, 'utf8')
        return JSON.parse(content)
      }

      case '.yaml': {
        const content = readFileSync(this._configPath, 'utf8')
        return yaml.parse(content)
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

  constructor(reportName?: string) {
    this._configCreated = false
    this._configPath = path.join(defaultReportBasePath, 'allurerc.json')
    this.reportName = reportName
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

export function getAllureConfig(configPath?: string, reportName?: string): AllureConfig {
  if (configPath) return new CustomConfig(configPath)

  return new DefaultConfig(reportName)
}
