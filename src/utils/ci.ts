import {Gitlab} from '@gitbeaker/rest'
import ci from 'ci-info'

import {GithubCiInfo} from '../lib/ci/info/github.js'
import {GitlabCiInfo} from '../lib/ci/info/gitlab.js'

export const gitlabClient: Gitlab = new Gitlab({
  host: process.env.CI_SERVER_URL || 'https://gitlab.com',
  token: process.env.GITLAB_AUTH_TOKEN,
})

export const ciInfo: GithubCiInfo | GitlabCiInfo | undefined = (() => {
  if (process.env.GITLAB_CI) return new GitlabCiInfo()
  if (process.env.GITHUB_WORKFLOW) return new GithubCiInfo()
})()

export const isCi = (() => Boolean(ciInfo) || ci.isCI)()
