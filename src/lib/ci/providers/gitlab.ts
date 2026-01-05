import {logger} from '../../../utils/logger.js'
import {GitlabCiInfo} from '../info/gitlab.js'
import {UrlSectionBuilder} from '../pr/url-section-builder.js'
import {gitlabClient} from '../utils.js'
import {BaseCiProvider} from './base.js'

export class GitlabCiProvider extends BaseCiProvider {
  private readonly ciInfo = new GitlabCiInfo()
  private readonly client = gitlabClient

  public async addReportSection() {
    return this.updateMode === 'description' ? this.updateMrDescription() : this.updateComment()
  }

  private async updateMrDescription() {
    const mrDescription = await this.getMrDescription()
    const updatedDescription = this.urlSectionBuilder.updatedDescription(mrDescription)

    logger.debug(`Updating MR description for mr '${this.ciInfo.mrIid}'`)
    await this.client.MergeRequests.edit(this.ciInfo.projectId!, this.ciInfo.mrIid, {
      description: updatedDescription,
    })
    logger.debug('MR description updated')
  }

  private async updateComment() {
    const comment = await this.getComment()
    const updatedComment = this.urlSectionBuilder.commentBody(comment?.body)
    const response = comment
      ? await this.client.MergeRequestNotes.edit(this.ciInfo.projectId!, this.ciInfo.mrIid, comment.id, {
          body: updatedComment,
        })
      : await this.client.MergeRequestNotes.create(this.ciInfo.projectId!, this.ciInfo.mrIid, updatedComment)
    logger.debug(`MR comment with id '${response.id}' ${comment ? 'updated' : 'created'} successfully`)
  }

  private async getMrDescription() {
    logger.debug(`Fetching MR description for mr '${this.ciInfo.mrIid}'`)
    const mr = await this.client.MergeRequests.show(this.ciInfo.projectId!, this.ciInfo.mrIid)
    logger.debug('Fetched MR description')
    return mr.description || ''
  }

  private async getComment() {
    logger.debug(`Fetching MR comment for mr '${this.ciInfo.mrIid}'`)
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
