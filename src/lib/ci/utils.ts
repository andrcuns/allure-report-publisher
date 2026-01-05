import {Gitlab} from '@gitbeaker/rest'
import ci from 'ci-info'
import {Octokit} from 'octokit'

import {GithubCiInfo} from './info/github.js'
import {GitlabCiInfo} from './info/gitlab.js'

export const gitlabClient: Gitlab = new Gitlab({
  host: process.env.CI_SERVER_URL || 'https://gitlab.com',
  token: process.env.GITLAB_AUTH_TOKEN,
})

export const githubClient: Octokit = new Octokit({
  auth: process.env.GITHUB_AUTH_TOKEN,
  baseUrl: process.env.GITHUB_API_URL || 'https://api.github.com',
})

export const ciInfo: GithubCiInfo | GitlabCiInfo | undefined = (() => {
  if (process.env.GITLAB_CI) return new GitlabCiInfo()
  if (process.env.GITHUB_WORKFLOW) return new GithubCiInfo()
})()

export const isCI = (() => Boolean(ciInfo) || ci.isCI)()
export const isPR = (() => ciInfo?.isPR ?? false)()
