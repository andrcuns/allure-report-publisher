import {logger} from '../../../utils/logger.js'
import {GithubCiInfo} from '../info/github.js'
import {UrlSectionBuilder} from '../pr/url-section-builder.js'
import {githubClient} from '../utils.js'
import {BaseCiProvider} from './base.js'

export class GithubCiProvider extends BaseCiProvider {
  private readonly ciInfo = new GithubCiInfo()
  private readonly client = githubClient
  private _prDescription?: string
  private _comment?: null | string | undefined

  public async addReportSection() {
    console.log(await this.getPrDescription())
    console.log(await this.getComment())
  }

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

    logger.debug(`Fetching PR description for pr '${this.ciInfo.prId}'`)
    const pr = await this.client.rest.pulls.get({
      owner: this.owner,
      repo: this.repo,
      // eslint-disable-next-line camelcase
      pull_number: this.ciInfo.prId!,
    })
    this._prDescription = pr.data.body || ''
    logger.debug('Fetched PR description')
    return this._prDescription
  }

  private async getComment() {
    if (this._comment !== undefined) return this._comment

    logger.debug(`Fetching PR comment for pr '${this.ciInfo.prId}'`)
    const comments = await this.client.rest.issues.listComments({
      owner: this.owner,
      repo: this.repo,
      // eslint-disable-next-line camelcase
      issue_number: this.ciInfo.prId!,
    })
    this._comment = comments.data.find((comment) => UrlSectionBuilder.match(comment.body_text))?.body ?? null
    if (this._comment) logger.debug('Found existing comment with report section')
    return this._comment
  }
}
