export type UpdatePRMode = 'actions' | 'comment' | 'description'
export type PluginName = 'allure2' | 'awesome' | 'classic' | 'csv' | 'dashboard'
export type SummaryJson = {
  stats: {
    total?: number
    passed?: number
    failed?: number
    broken?: number
    retries?: number
    flaky?: number
    skipped?: number
    unknown?: number
  }
  status: string
}
