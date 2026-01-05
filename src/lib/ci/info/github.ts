import {readFileSync} from 'node:fs'

import {GithubCiProvider} from '../providers/github.js'
import {BaseCiInfo} from './base.js'

type GitHubEvent = {
  number: number
  pull_request: {
    head: {
      sha: string
    }
  }
}

export class GithubCiInfo extends BaseCiInfo {
  private _githubEvent?: GitHubEvent

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

  public get CiProviderClass() {
    return GithubCiProvider
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
    return (
      process.env[BaseCiInfo.ALLURE_JOB_NAME] ||
      process.env.GITHUB_JOB ||
      (() => {
        throw new Error('Build name not found in environment variables')
      })()
    )
  }

  public get repository() {
    return process.env.GITHUB_REPOSITORY
  }

  public get buildUrl() {
    return `${this.serverUrl}/${this.repository}/actions/runs/${this.runId}`
  }

  public get prId() {
    return this.githubEvent.number
  }

  private get githubEvent(): GitHubEvent {
    if (this._githubEvent) return this._githubEvent

    const eventPath = process.env.GITHUB_EVENT_PATH
    if (!eventPath) {
      throw new Error('Failed to get GitHub event data: GITHUB_EVENT_PATH is not set')
    }

    this._githubEvent = JSON.parse(readFileSync(eventPath, 'utf8')) as GitHubEvent
    return this._githubEvent
  }

  public getPrShaUrl() {
    const sha = this.githubEvent.pull_request?.head?.sha
    if (!sha || !this.prId) return

    const shortSha = sha.slice(0, 8)
    return `[${shortSha}](${this.serverUrl}/${this.repository}/pull/${this.prId}/commits/${sha})`
  }
}
