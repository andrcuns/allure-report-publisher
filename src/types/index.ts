/**
 * Shared type definitions for allure-report-publisher
 */
export type StorageType = 'gcs' | 'gitlab-artifacts' | 's3'
export type UpdatePRMode = 'actions' | 'comment' | 'description'
export type SummaryType = 'behaviors' | 'packages' | 'suites' | 'total'
export type SummaryTableType = 'ascii' | 'markdown'
export type PluginName = 'allure2' | 'awesome' | 'classic' | 'csv' | 'dashboard'
