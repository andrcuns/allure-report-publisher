/**
 * Shared type definitions for allure-report-publisher
 */

/**
 * Supported cloud storage provider types
 */
export type StorageType = 'gcs' | 'gitlab-artifacts' | 's3'

/**
 * PR/MR update modes
 */
export type UpdatePRMode = 'actions' | 'comment' | 'description'

/**
 * Summary table types
 */
export type SummaryType = 'behaviors' | 'packages' | 'suites' | 'total'

/**
 * Summary table format types
 */
export type SummaryTableType = 'ascii' | 'markdown'

/**
 * Validation error interface
 */
export interface ValidationError {
  field: string
  message: string
}
