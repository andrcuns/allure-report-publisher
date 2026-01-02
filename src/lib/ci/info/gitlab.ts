import {BaseCiInfo} from './base.js'

export class GitlabCiInfo extends BaseCiInfo {
  public static readonly DEFAULT_PAGES_DOMAIN = 'gitlab.io'

  public get pr() {
    return Boolean((this.allureProject && this.allureMrIid) || this.mrIid)
  }

  public get runId() {
    return process.env[BaseCiInfo.ALLURE_RUN_ID] || process.env.CI_PIPELINE_ID
  }

  public get jobId() {
    return process.env.CI_JOB_ID
  }

  public get projectPath() {
    return process.env.CI_PROJECT_PATH
  }

  public get projectName() {
    return process.env.CI_PROJECT_NAME
  }

  public get projectId() {
    return process.env.CI_PROJECT_ID
  }

  public get buildDir() {
    return process.env.CI_PROJECT_DIR
  }

  public get branch() {
    return process.env.CI_MERGE_REQUEST_SOURCE_BRANCH_NAME || process.env.CI_COMMIT_REF_NAME
  }

  public get serverUrl() {
    return process.env.CI_SERVER_URL
  }

  public get buildUrl() {
    return process.env.CI_PIPELINE_URL
  }

  public get allureProject() {
    return process.env.ALLURE_PROJECT_PATH
  }

  public get mrIid() {
    return this.allureMrIid || process.env.CI_MERGE_REQUEST_IID
  }

  public get allureMrIid() {
    return process.env.ALLURE_MERGE_REQUEST_IID
  }

  public get buildName() {
    return process.env[BaseCiInfo.ALLURE_JOB_NAME] || this.jobName
  }

  public get jobName() {
    return process.env.CI_JOB_NAME
  }

  public get pagesDomain() {
    return process.env.CI_PAGES_DOMAIN
  }
}
