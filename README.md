# allure-report-publisher

[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/andrcuns/allure-report-publisher?color=blue&label=docker&sort=semver)](https://hub.docker.com/r/andrcuns/allure-report-publisher)
[![Docker Pulls](https://img.shields.io/docker/pulls/andrcuns/allure-report-publisher)](https://hub.docker.com/r/andrcuns/allure-report-publisher)
![Workflow status](https://github.com/andrcuns/allure-report-publisher/workflows/Test/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/210eaa4f74588fb08313/maintainability)](https://codeclimate.com/github/andrcuns/allure-report-publisher/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/210eaa4f74588fb08313/test_coverage)](https://codeclimate.com/github/andrcuns/allure-report-publisher/test_coverage)

Upload your report to a file storage of your choice.

![Demo](demo.gif)

# Installation

## Rubygems

```shell
gem install allure-report-uploader
```

## Docker

```shell
docker pull andrcuns/allure-report-publisher:latest
```

# Usage

```shell
$ (allure-report-publisher|docker run --rm andrcuns/allure-report-publisher:latest) upload --help
Command:
  allure-report-publisher upload

Usage:
  allure-report-publisher upload TYPE

Description:
  Generate and upload allure report

Arguments:
  TYPE                              # REQUIRED Cloud storage type: (s3/gcs)

Options:
  --results-glob=VALUE              # Glob pattern to return allure results directories. Required: true
  --bucket=VALUE                    # Bucket name. Required: true
  --prefix=VALUE                    # Optional prefix for report path. Required: false
  --update-pr=VALUE                 # Add report url to PR via comment or description update. Required: false: (comment/description/actions)
  --report-title=VALUE              # Title for url section in PR comment/description. Required: false, default: "Allure Report"
  --report-name=VALUE               # Custom report name in final Allure report. Required: false
  --summary=VALUE                   # Additionally add summary table to PR comment or description. Required: false: (behaviors/suites/packages/total), default: "total"
  --summary-table-type=VALUE        # Summary table type. Required: false: (ascii/markdown), default: "ascii"
  --base-url=VALUE                  # Use custom base url instead of default cloud provider one. Required: false
  --parallel=VALUE                  # Number of parallel threads to use for report file upload to cloud storage. Required: false, default: 8
  --[no-]flaky-warning-status       # Mark run with a '!' status in PR comment/description if report contains flaky tests, default: false
  --[no-]collapse-summary           # Create summary as a collapsible section, default: false
  --[no-]copy-latest                # Keep copy of latest report at base prefix path, default: false
  --[no-]color                      # Force color output
  --[no-]ignore-missing-results     # Ignore missing allure results, default: false
  --[no-]debug                      # Print additional debug output, default: false
  --help, -h                        # Print this help

Examples:
  allure-report-publisher upload s3 --results-glob='path/to/allure-results' --bucket=my-bucket
  allure-report-publisher upload gcs --results-glob='paths/to/**/allure-results' --bucket=my-bucket --prefix=my-project/prs
```

## Environment variables

All named options can be configured via environment variables. Environment variables are prefixed with `ALLURE_` and uppercased.

Example: `--results-glob` can be configured via `ALLURE_RESULTS_GLOB`

# Storage providers

Multiple cloud storage providers are supported

## AWS S3

Requires environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` or credentials file `~/.aws/credentials`

Additional configuration:

- `AWS_REGION`: configure s3 region, default: `us-east-1`
- `AWS_FORCE_PATH_STYLE`: when set to true, the bucket name is always left in the request URI and never moved to the host as a sub-domain, default: `false`
- `AWS_ENDPOINT`: custom s3 endpoint when used with other s3 compatible storage

## Google Cloud Storage

Requires on of the following environment variables.

credentials.json file location:

- `STORAGE_CREDENTIALS`
- `STORAGE_KEYFILE`
- `GOOGLE_CLOUD_CREDENTIALS`
- `GOOGLE_CLOUD_KEYFILE`
- `GCLOUD_KEYFILE`

credentials.json contents:

- `GOOGLE_CLOUD_CREDENTIALS_JSON`
- `STORAGE_CREDENTIALS_JSON`
- `STORAGE_KEYFILE_JSON`
- `GOOGLE_CLOUD_CREDENTIALS_JSON`
- `GOOGLE_CLOUD_KEYFILE_JSON`
- `GCLOUD_KEYFILE_JSON`

# CI

`allure-report-publisher` will automatically detect if used in CI environment and add relevant executor info and history.

Following CI providers are supported:

- Github Actions
- Gitlab CI

## Pull requests

It is possible to update pull requests with urls to published reports and execution summary.

- `--update-pr=(comment|description|actions)`: post report urls in pr description, as a comment or step summary for github actions
- `--summary=(behaviors|suites|packages|total)`: add execution summary table
- `--summary-table-type=(ascii|markdown)`: use markdown or ascii table formatting
- `--[no-]collapse-summary`: add summary in collapsable section

Example:

---

`# Allure report`

`allure-report-publisher` generated test report!

**rspec**: ✅ [test report](https://storage.googleapis.com/allure-test-reports/allure-report-publisher/refs/heads/main/index.html) for [1b756f48](https://github.com/andrcuns/allure-report-publisher/commit/HEAD)

```markdown
+--------------------------------------------------------+
|                   total summary                        |
+-----------+--------+--------+---------+-------+--------+
|           | passed | failed | skipped | flaky | result |
+-----------+--------+--------+---------+-------+--------+
| Total     | 100    | 0      | 2       | 0     | ✅     |
+-----------+--------+--------+---------+-------+--------+
```

---

## Github Actions

Additional configuration is done via environment variables

Authentication for PR updates:

- `GITHUB_AUTH_TOKEN`: github auth token with api access

Following environment variables can override default CI values:

- `ALLURE_JOB_NAME`: overrides default `GITHUB_JOB` value which is used as name for report url section
- `ALLURE_RUN_ID`: overrides default `GITHUB_RUN_ID` value which is used as name for the run number

### allure-publish-action

[allure-publish-action](https://github.com/marketplace/actions/allure-publish-action) can be used to easily run report publishing from any github actions job.

## Gitlab CI

Additional configuration is done via environment variables

### Authentication

Authentication for MR updates:

- `GITLAB_AUTH_TOKEN`: gitlab access token with api access

### CI values

Following environment variables can override default CI values:

- `ALLURE_JOB_NAME`: overrides default `CI_JOB_NAME` value which is used as name for report url section
- `ALLURE_RUN_ID`: overrides default `CI_PIPELINE_ID` value which is used as name for the run number

In case merge request triggers a downstream pipeline yet you want to update original merge request, overriding following environment variables might be useful:

- `ALLURE_PROJECT_PATH`: overrides default `CI_PROJECT_PATH` value
- `ALLURE_MERGE_REQUEST_IID`: overrides default `CI_MERGE_REQUEST_IID` value
- `ALLURE_COMMIT_SHA`: overrides default `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA` or `CI_COMMIT_SHA` values

### Summary comment behavior

If reporter is executed with options `--update-pr=comment` and `--unresolved-discussion-on-failure`, it's possible to additionally configure the unresolved discussion note:

- `ALLURE_FAILURE_ALERT_COMMENT`: comment added to create unresolved discussion note, default: `There are some test failures that need attention`

### CI/CD catalog resource

[allure-report-publisher CI/CD catalog resource](https://gitlab.com/andrcuns/allure-report-publisher) can be used to easily integrate report publishing in to Gitlab CI pipelines.

# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/andrcuns/allure-report-publisher>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).

# License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Code of Conduct

Everyone interacting in the allure-report-publisher project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).
