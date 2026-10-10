import {GitlabCiProvider} from '../providers/gitlab.js'
import {BaseCiInfo} from './base.js'

export class GitlabCiInfo extends BaseCiInfo {
  public executorJson(reportUrl: string): Record<string, string | undefined> {
    return {
      name: 'GitLab',
      type: 'gitlab',
      reportName: 'AllureReport',
      reportUrl,
      url: this.serverUrl,
      buildUrl: this.buildUrl,
      buildOrder: this.runId,
      buildName: this.buildName,
    }
  }

  public get CiProviderClass() {
    return GitlabCiProvider
  }

  public get isPR() {
    return Boolean((this.allureProject && this.allureMrIid) || this.mrIid)
  }

  public get runId() {
    return process.env[BaseCiInfo.ALLURE_RUN_ID] || process.env.CI_PIPELINE_ID
  }

  public get projectPath() {
    return process.env.CI_PROJECT_PATH
  }

  public get projectName() {
    return process.env.CI_PROJECT_NAME
  }

  public get projectId() {
    return process.env.CI_PROJECT_ID
  }

  public get serverUrl() {
    return process.env.CI_SERVER_URL
  }

  public get buildUrl() {
    return process.env.CI_PIPELINE_URL
  }

  public get allureProject() {
    return process.env.ALLURE_PROJECT_PATH
  }

  public get mrIid() {
    const rawIid = this.allureMrIid || process.env.CI_MERGE_REQUEST_IID
    const iid = Number(rawIid)

    return Number.isNaN(iid) ? undefined : iid
  }

  public get allureMrIid() {
    return process.env.ALLURE_MERGE_REQUEST_IID
  }

  public get buildName() {
    return (
      process.env[BaseCiInfo.ALLURE_JOB_NAME] ||
      this.jobName ||
      (() => {
        throw new Error('Build name not found in environment variables')
      })()
    )
  }

  public get jobName() {
    return process.env.CI_JOB_NAME
  }

  public getPrShaUrl() {
    const sha = process.env.CI_MERGE_REQUEST_SOURCE_SHA || process.env.CI_COMMIT_SHA
    if (!sha || !this.mrIid || !this.projectPath) return

    const shortSha = sha.slice(0, 8)
    return `[${shortSha}](${this.serverUrl}/${this.projectPath}/-/merge_requests/${this.mrIid}/diffs?commit_id=${sha})`
  }
}
