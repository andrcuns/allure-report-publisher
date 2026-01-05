import {GithubCiInfo} from '../info/github.js'
import {UrlSectionBuilder} from '../pr/url-section-builder.js'
import {githubClient} from '../utils.js'
import {BaseCiProvider} from './base.js'

export class GithubCiProvider extends BaseCiProvider {
  private readonly ciInfo = new GithubCiInfo()
  private readonly client = githubClient
  private _prDescription?: string
  private _comment?: string | undefined

  public async updatePr() {}

  private isActionsType() {
    return this.updateMode === 'actions'
  }

  private get owner() {
    return this.ciInfo.repository!.split('/')[0]
  }

  private get repo() {
    return this.ciInfo.repository!.split('/')[1]
  }

  private async getPrDescription() {
    if (this._prDescription) return this._prDescription

    const pr = await this.client.rest.pulls.get({
      owner: this.owner,
      repo: this.repo,
      // eslint-disable-next-line camelcase
      pull_number: this.ciInfo.prId!,
    })
    this._prDescription = pr.data.body || ''
    return this._prDescription
  }

  private async getComment() {
    if (this._comment) return this._comment

    const comments = await this.client.rest.issues.listComments({
      owner: this.owner,
      repo: this.repo,
      // eslint-disable-next-line camelcase
      issue_number: this.ciInfo.prId!,
    })
    this._comment = comments.data.find((comment) => UrlSectionBuilder.match(comment.body_text))?.body
    return this._comment
  }
}
