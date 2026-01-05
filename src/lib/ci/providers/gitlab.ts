import {logger} from '../../../utils/logger.js'
import {GitlabCiInfo} from '../info/gitlab.js'
import {UrlSectionBuilder} from '../pr/url-section-builder.js'
import {gitlabClient} from '../utils.js'
import {BaseCiProvider} from './base.js'

export class GitlabCiProvider extends BaseCiProvider {
  private readonly ciInfo = new GitlabCiInfo()
  private readonly client = gitlabClient

  protected async performUpdate() {
    return this.updateMode === 'description' ? this.updatePrDescription() : this.updateComment()
  }

  private async updatePrDescription() {
    const prDescription = await this.getPrDescription()
    const updatedDescription = this.urlSectionBuilder.updatedPrDescription(prDescription)

    logger.debug(`Updating PR description for pr '${this.ciInfo.mrIid}'`)
    await this.client.MergeRequests.edit(this.ciInfo.projectId!, this.ciInfo.mrIid, {
      description: updatedDescription,
    })
    logger.debug('PR description updated')
  }

  private async updateComment() {
    const comment = await this.getComment()
    const updatedComment = this.urlSectionBuilder.commentBody(comment?.body)
    const response = comment
      ? await this.client.MergeRequestNotes.edit(this.ciInfo.projectId!, this.ciInfo.mrIid, comment.id, {
          body: updatedComment,
        })
      : await this.client.MergeRequestNotes.create(this.ciInfo.projectId!, this.ciInfo.mrIid, updatedComment)
    logger.debug(`PR comment with id '${response.id}' ${comment ? 'updated' : 'created'} successfully`)
  }

  private async getPrDescription() {
    logger.debug(`Fetching PR description for pr '${this.ciInfo.mrIid}'`)
    const mr = await this.client.MergeRequests.show(this.ciInfo.projectId!, this.ciInfo.mrIid)
    logger.debug('Fetched PR description')
    return mr.description || ''
  }

  private async getComment() {
    logger.debug(`Fetching PR comment for pr '${this.ciInfo.mrIid}'`)
    const comments = await this.client.MergeRequestNotes.all(this.ciInfo.projectId!, this.ciInfo.mrIid, {
      sort: 'asc',
      orderBy: 'created_at',
      perPage: 100,
    })
    const comment = comments.find((comment) => UrlSectionBuilder.match(comment.body))
    if (comment) {
      logger.debug('Found existing comment with report section')
    } else {
      logger.debug('No existing comment with report section found')
    }

    return comment
  }
}
