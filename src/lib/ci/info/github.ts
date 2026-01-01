import {BaseCiInfo} from './base.js'

export class GithubCiInfo extends BaseCiInfo {
  public get pr() {
    return process.env.GITHUB_EVENT_NAME === 'pull_request'
  }

  public get runId() {
    return process.env[BaseCiInfo.ALLURE_RUN_ID] || process.env.GITHUB_RUN_ID
  }

  public get serverUrl() {
    return process.env.GITHUB_SERVER_URL
  }

  public get buildName() {
    return process.env[BaseCiInfo.ALLURE_JOB_NAME] || process.env.GITHUB_JOB
  }

  public get repository() {
    return process.env.GITHUB_REPOSITORY
  }

  public get buildUrl() {
    return `${this.serverUrl}/${this.repository}/actions/runs/${this.runId}`
  }
}
