import {readFileSync, writeFileSync} from 'node:fs'

import {logger} from '../../../utils/logger.js'
import {GithubCiInfo} from '../info/github.js'
import {UrlSectionBuilder} from '../pr/url-section-builder.js'
import {githubClient} from '../utils.js'
import {BaseCiProvider} from './base.js'

interface Comment {
  body?: string
  id: number
}

export class GithubCiProvider extends BaseCiProvider {
  private readonly ciInfo = new GithubCiInfo()
  private readonly client = githubClient

  public async addReportSection() {
    if (this.isActionsType) return writeFileSync(this.stepSummaryFile(), this.urlSectionBuilder.commentBody())
    return this.updateMode === 'description' ? this.updatePrDescription() : this.updateComment()
  }

  private get isActionsType() {
    return this.updateMode === 'actions'
  }

  private get owner() {
    return this.ciInfo.repository!.split('/')[0]
  }

  private get repo() {
    return this.ciInfo.repository!.split('/')[1]
  }

  private async updatePrDescription() {
    const prDescription = await this.getPrDescription()
    const updatedDescription = this.urlSectionBuilder.updatedDescription(prDescription)

    logger.debug(`Updating PR description for pr '${this.ciInfo.prId}'`)
    await this.client.rest.pulls.update({
      owner: this.owner,
      repo: this.repo,
      // eslint-disable-next-line camelcase
      pull_number: this.ciInfo.prId!,
      body: updatedDescription,
    })
    logger.debug('PR description updated')
  }

  private async updateComment() {
    const comment = await this.getComment()
    const updatedComment = this.urlSectionBuilder.commentBody(comment?.body)
    const response = comment
      ? await this.client.rest.issues.updateComment({
          owner: this.owner,
          repo: this.repo,
          body: updatedComment,
          // eslint-disable-next-line camelcase
          comment_id: comment.id,
        })
      : await this.client.rest.issues.createComment({
          owner: this.owner,
          repo: this.repo,
          body: updatedComment,
          // eslint-disable-next-line camelcase
          issue_number: this.ciInfo.prId!,
        })
    logger.debug(`PR comment with id '${response.data.id}' ${comment ? 'updated' : 'created'} successfully`)
  }

  private async getPrDescription() {
    logger.debug(`Fetching PR description for pr '${this.ciInfo.prId}'`)
    const pr = await this.client.rest.pulls.get({
      owner: this.owner,
      repo: this.repo,
      // eslint-disable-next-line camelcase
      pull_number: this.ciInfo.prId!,
    })
    logger.debug('Fetched PR description')
    return pr.data.body || ''
  }

  private async getComment() {
    logger.debug(`Fetching PR comment for pr '${this.ciInfo.prId}'`)
    const comments = await this.client.rest.issues.listComments({
      owner: this.owner,
      repo: this.repo,
      // eslint-disable-next-line camelcase
      issue_number: this.ciInfo.prId!,
    })
    const comment = (comments.data.find((comment) => UrlSectionBuilder.match(comment.body)) as Comment)
    if (comment) {
      logger.debug('Found existing comment with report section')
    } else {
      logger.debug('No existing comment with report section found')
    }

    return comment
  }

  private stepSummaryFile() {
    const path = process.env.GITHUB_STEP_SUMMARY
    if (!path) {
      throw new Error('GITHUB_STEP_SUMMARY is not set in the environment')
    }

    if (!readFileSync(path, 'utf8')) {
      throw new Error('GITHUB_STEP_SUMMARY file is empty')
    }

    return path
  }
}
