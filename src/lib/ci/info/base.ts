export abstract class BaseCiInfo {
  public static ALLURE_JOB_NAME = 'ALLURE_JOB_NAME'
  public static ALLURE_RUN_ID = 'ALLURE_RUN_ID'

  public abstract isPR: boolean
  public abstract buildName: string
  public abstract runId: string | undefined
}
