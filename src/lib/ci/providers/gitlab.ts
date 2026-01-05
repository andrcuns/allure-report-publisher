import {GitlabCiInfo} from '../info/gitlab.js'
import {gitlabClient} from '../utils.js'
import {BaseCiProvider} from './base.js'

export class GitlabCiProvider extends BaseCiProvider {
  private readonly ciInfo = new GitlabCiInfo()
  private readonly client = gitlabClient
  private _mrDescription?: string
  private _comment?: string | undefined

  protected async performUpdate() {}
}
