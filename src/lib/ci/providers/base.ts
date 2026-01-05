import {UpdatePRMode} from '../../../types/index.js'
import {spin} from '../../../utils/spinner.js'
import {UrlSectionBuilder} from '../pr/url-section-builder.js'

export abstract class BaseCiProvider {
  private readonly _urlSectionBuilder
  private readonly _updateMode: UpdatePRMode

  constructor(urlSectionBuilder: UrlSectionBuilder, updateMode: UpdatePRMode) {
    this._urlSectionBuilder = urlSectionBuilder
    this._updateMode = updateMode
  }

  protected get urlSectionBuilder() {
    return this._urlSectionBuilder
  }

  protected get updateMode() {
    return this._updateMode
  }

  protected abstract performUpdate(): Promise<void>

  public async addReportSection() {
    await spin(this.performUpdate(), `Adding report section to the ${this.updateMode}`, {ignoreError: true})
  }
}
