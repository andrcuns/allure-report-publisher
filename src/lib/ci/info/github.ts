import {BaseCiInfo} from './base.js'

export class GithubCiInfo extends BaseCiInfo {
  public executorJson(reportUrl: string): Record<string, string | undefined> {
    return {
      name: 'GitHub',
      type: 'github',
      reportName: 'AllureReport',
      reportUrl,
      url: this.serverUrl,
      buildUrl: this.buildUrl,
      buildOrder: this.runId,
      buildName: this.buildName,
    }
  }

  public get isPR() {
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
