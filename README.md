# allure-report-publisher

[![Gem Version](https://img.shields.io/gem/v/allure-report-publisher?color=red)](https://rubygems.org/gems/allure-report-publisher)
[![Gem Pulls](https://img.shields.io/gem/dt/allure-report-publisher)](https://rubygems.org/gems/allure-report-publisher)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/andrcuns/allure-report-publisher?color=blue&label=docker&sort=semver)](https://hub.docker.com/r/andrcuns/allure-report-publisher)
[![Docker Pulls](https://img.shields.io/docker/pulls/andrcuns/allure-report-publisher)](https://hub.docker.com/r/andrcuns/allure-report-publisher)
![Workflow status](https://github.com/andrcuns/allure-report-publisher/workflows/Test/badge.svg)
[![Test Report](https://img.shields.io/badge/report-allure-blue.svg)](https://storage.googleapis.com/allure-test-reports/allure-report-publisher/refs/heads/main/index.html)
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
  --results-glob=VALUE              # Allure results files glob. Required: true
  --bucket=VALUE                    # Bucket name. Required: true
  --prefix=VALUE                    # Optional prefix for report path. Required: false
  --update-pr=VALUE                 # Add report url to PR via comment or description update. Required: false: (comment/description)
  --[no-]copy-latest                # Keep copy of latest report at base prefix path, default: false
  --[no-]color                      # Toggle color output, default: false
  --help, -h                        # Print this help

Examples:
  allure-report-publisher upload s3 --results-glob='path/to/allure-result/**/*' --bucket=my-bucket
  allure-report-publisher upload gcs --results-glob='path/to/allure-result/**/*' --bucket=my-bucket --prefix=my-project/prs
```

# Storage providers

Multiple cloud storage providers are supported

## AWS S3

Requires environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` or credentials file `~/.aws/credentials`

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

It is possible to update pull requests with urls to published reports.

- `--update-pr=(comment|description)`: post report urls in pr description or as a comment

## Github Actions

Additional configuration is done via environment variables

Authentication for PR updates:

- `GITHUB_AUTH_TOKEN`: github auth token with api access

Following environment variables can override default CI values:

- `ALLURE_JOB_NAME`: overrides default `GITHUB_JOB` value which is used as name for report url section

## Gitlab CI

Additional configuration is done via environment variables

Authentication for MR updates:

- `GITLAB_AUTH_TOKEN`: gitlab access token with api access

Following environment variables can override default CI values:

- `ALLURE_JOB_NAME`: overrides default `CI_JOB_NAME` value which is used as name for report url section

In case merge request triggers a downstream pipeline yet you want to update original merge request, overriding following environment variables might be useful:

- `ALLURE_PROJECT`: overrides default `CI_PROJECT_PATH` value
- `ALLURE_MR_IID`: overrides default `CI_MERGE_REQUEST_IID` value
- `ALLURE_SHA`: overrides default `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA` or `CI_COMMIT_SHA` values

# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/andrcuns/allure-report-publisher>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).

# License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Code of Conduct

Everyone interacting in the allure-report-publisher project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).
