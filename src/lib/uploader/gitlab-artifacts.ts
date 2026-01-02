import {Gitlab} from '@gitbeaker/rest'
import {writeFileSync} from 'node:fs'

import {gitlabClient} from '../../utils/ci.js'
import {logger} from '../../utils/logger.js'
import {GitlabCiInfo} from '../ci/info/gitlab.js'
import {BaseUploader} from './base.js'

export class GitlabArtifactsUploader extends BaseUploader {
  private readonly client: Gitlab = gitlabClient

  constructor(...opts: ConstructorParameters<typeof BaseUploader>) {
    super(...opts)

    // gitlab artifacts uploader does not support creating latest copy
    this.copyLatest = opts[0].copyLatest
  }

  protected get ciInfo(): GitlabCiInfo {
    return new GitlabCiInfo()
  }

  public async downloadHistory() {
    super.downloadHistory()

    const previousJobId = await this.getPreviousJobId()
    if (!previousJobId) throw new Error('Could not determine previous job ID for downloading history artifacts')

    await this.getHistoryFromArtifacts(previousJobId)
  }

  // gitlab api does not expose api to upload artifacts, all uploading is handled by gitlab ci itself
  // upload method only outputs the report urls
  public async upload() {
    this.outputReportUrls()
  }

  // no-op: report upload should be handled by GitLab CI job
  protected async uploadHistory() {}

  // no-op: report upload should be handled by GitLab CI job
  protected async uploadReport() {}

  // no-op: Gitlab CI does not support creating latest copy
  protected async createLatestCopy() {}

  // Built in variables of gitlab CI return incorrect pages hostname so it needs to be built manually
  protected reportUrlBase() {
    const {projectPath, serverUrl} = this.ciInfo

    if (!projectPath) {
      throw new Error('Missing required CI_PROJECT_PATH for generating GitLab Pages URL')
    }

    const topLevelGroup = projectPath.split('/')[0]
    if (!serverUrl) {
      return `https://${topLevelGroup}.${GitlabCiInfo.DEFAULT_PAGES_DOMAIN}`
    }

    try {
      const url = new URL(serverUrl)
      const host = url.hostname
      const scheme = url.protocol.replace(':', '') || 'https'
      return `${scheme}://${topLevelGroup}.${host}`
    } catch {
      return `https://${topLevelGroup}.${GitlabCiInfo.DEFAULT_PAGES_DOMAIN}`
    }
  }

  protected getReportUrls() {
    const base = this.reportUrlBase()
    const path = this.reportPath.replace('./', '')
    const {projectName, jobId} = this.ciInfo

    return {
      run: this.plugins.map(
        (plugin) => `${base}/-/${projectName}/-/jobs/${jobId}/artifacts/${path}/${plugin}/index.html`,
      ),
    }
  }

  private async getPreviousJobId() {
    const {projectId, branch, buildName, runId} = this.ciInfo

    if (!projectId || !branch || !buildName || !runId) {
      throw new Error('Missing required CI info for fetching previous job ID')
    }

    logger.debug(`Fetching previous pipelines for ref: ${branch}`)
    const pipelines = await this.client.Pipelines.all(projectId, {
      ref: branch,
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
    logger.debug(`Downloading history file from artifacts of job ID: '${jobId}' at path: '${this.historyPath}'`)
    try {
      const artifact = await this.client.JobArtifacts.downloadArchive(this.ciInfo.projectId!, {
        jobId: Number(jobId),
        artifactPath: this.historyPath,
      })
      writeFileSync(this.historyPath, await artifact.text())
      logger.debug(`Successfully downloaded history artifact from job ID: '${jobId}'`)
    } catch (error) {
      throw new Error(`Failed to download history artifact from job ID: '${jobId}'. Err: '${(error as Error).message}'`)
    }
  }
}
