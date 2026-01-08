import {Gitlab} from '@gitbeaker/rest'
import {mkdirSync, writeFileSync} from 'node:fs'
import path from 'node:path'

import {logger} from '../../../utils/logger.js'
import {GitlabCiInfo} from '../../ci/info/gitlab.js'
import {gitlabClient} from '../../ci/utils.js'

export class GitlabArtifactsUploader {
  private readonly client: Gitlab
  private readonly ciInfo: GitlabCiInfo
  private readonly historyPath: string
  private readonly reportPath: string
  private readonly plugins: string[]
  private _reportUrls: string[] | undefined

  constructor(opts: {historyPath: string; reportPath: string; plugins: string[]}) {
    this.historyPath = opts.historyPath
    this.reportPath = opts.reportPath
    this.plugins = opts.plugins
    this.client = gitlabClient
    this.ciInfo = new GitlabCiInfo()
  }

  public async downloadHistory() {
    const historyDir = path.dirname(this.historyPath)
    logger.debug(`Creating destination directory for history file at ${historyDir}`)
    mkdirSync(historyDir, {recursive: true})

    const previousJobId = await this.getPreviousJobId()
    if (!previousJobId) throw new Error('Could not determine previous job ID for downloading history artifacts')

    await this.getHistoryFromArtifacts(previousJobId)
  }

  public outputReportUrls() {
    const urls = this.getReportUrls()
    for (const url of urls) logger.info(`- ${url}`)
  }

  public reportUrl() {
    const urls = this.getReportUrls()
    return urls[0]
  }

  // Built in variables of gitlab CI return incorrect pages hostname so it needs to be built manually
  protected reportUrlBase() {
    const {projectPath, serverUrl, pagesDomain} = this.ciInfo

    if (!projectPath) {
      throw new Error('Missing required CI_PROJECT_PATH for generating GitLab Pages URL')
    }

    const topLevelGroup = projectPath.split('/')[0]

    try {
      const url = new URL(serverUrl!)
      const scheme = url.protocol.replace(':', '') || 'https'
      return `${scheme}://${topLevelGroup}.${pagesDomain}`
    } catch {
      logger.debug(`Failed to construct pages domain based on server url, using default https scheme`)
      return `https://${topLevelGroup}.${pagesDomain || GitlabCiInfo.DEFAULT_PAGES_DOMAIN}`
    }
  }

  protected getReportUrls() {
    if (this._reportUrls !== undefined) return this._reportUrls

    const base = this.reportUrlBase()
    const relativePath = path.relative(this.ciInfo.buildDir || '', this.reportPath)
    const {projectName, jobId} = this.ciInfo
    const urls = [`${base}/-/${projectName}/-/jobs/${jobId}/artifacts/${relativePath}/index.html`]
    if (this.plugins.length > 1) {
      urls.push(
        ...this.plugins.map(
          (plugin) => `${base}/-/${projectName}/-/jobs/${jobId}/artifacts/${relativePath}/${plugin}/index.html`,
        ),
      )
    }

    this._reportUrls = urls
    return urls
  }

  private async getPreviousJobId() {
    const {projectId, branch, buildName, runId, pipelineSource} = this.ciInfo

    if (!projectId || !branch || !buildName || !runId) {
      throw new Error('Missing required CI info for fetching previous job ID')
    }

    logger.debug(`Fetching previous pipelines for ref: ${branch}`)
    const pipelines = await this.client.Pipelines.all(projectId, {
      ref: branch,
      source: pipelineSource,
      perPage: 100,
      maxPages: 1,
    })

    const pipelineIds = pipelines.map((p) => p.id)

    if (pipelineIds.length < 2) {
      throw new Error('Not enough pipelines found')
    }

    const currentPipelineIndex = pipelineIds.indexOf(Number(runId))
    if (currentPipelineIndex === -1) {
      throw new Error(`Current pipeline ${runId} not found in list`)
    }

    const previousPipelineIndex = currentPipelineIndex + 1
    if (previousPipelineIndex >= pipelineIds.length) {
      throw new Error('No previous pipeline found')
    }

    const previousPipelineId = pipelineIds[previousPipelineIndex]
    logger.debug(`Fetching last job id from pipeline: ${previousPipelineId}`)
    const failedJobs = await this.client.Jobs.all(projectId, {
      pipelineId: previousPipelineId,
      scope: 'failed',
      includeRetried: false,
      perPage: 100,
    })
    const successfulJobs = await this.client.Jobs.all(projectId, {
      pipelineId: previousPipelineId,
      scope: 'success',
      includeRetried: false,
      perPage: 100,
    })

    const previousJob = [...failedJobs, ...successfulJobs].find((job) => job.name === buildName)
    if (previousJob) {
      logger.debug(`Found previous job ID: ${previousJob.id} for job name: '${buildName}'`)
      return previousJob.id
    }

    throw new Error(`No previous job found with name: ${buildName}`)
  }

  private async getHistoryFromArtifacts(jobId: number | string) {
    const artifactPath = path.relative(this.ciInfo.buildDir || '', this.historyPath)
    logger.debug(`Downloading history file from artifacts of job ID: '${jobId}' at path: '${artifactPath}'`)
    try {
      const artifact = await this.client.JobArtifacts.downloadArchive(this.ciInfo.projectId!, {
        jobId: Number(jobId),
        artifactPath,
      })
      writeFileSync(this.historyPath, await artifact.text())
      logger.debug(`Successfully downloaded history artifact from job ID: '${jobId}'`)
    } catch (error) {
      throw new Error(`Failed to download history artifact from job ID: '${jobId}'. Err: '${(error as Error).message}'`)
    }
  }
}
