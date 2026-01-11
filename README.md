# allure-report-publisher

[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/andrcuns/allure-report-publisher?color=blue&label=docker&sort=semver)](https://hub.docker.com/r/andrcuns/allure-report-publisher)
[![Docker Pulls](https://img.shields.io/docker/pulls/andrcuns/allure-report-publisher)](https://hub.docker.com/r/andrcuns/allure-report-publisher)
[![codecov](https://codecov.io/gh/andrcuns/allure-report-publisher/graph/badge.svg?token=YT3U8GYHHP)](https://codecov.io/gh/andrcuns/allure-report-publisher)
![Workflow status](https://github.com/andrcuns/allure-report-publisher/workflows/Test/badge.svg)

Upload your report to a file storage of your choice.

![Demo](demo.gif)

# Usage

<!-- usage -->
```sh-session
$ npm install -g allure-report-publisher
$ allure-report-publisher COMMAND
running command...
$ allure-report-publisher (--version)
allure-report-publisher/5.0.1 linux-x64 node-v25.2.1
$ allure-report-publisher --help [COMMAND]
USAGE
  $ allure-report-publisher COMMAND
...
```
<!-- usagestop -->
<!-- commands -->
* [`allure-report-publisher upload gcs`](#allure-report-publisher-upload-gcs)
* [`allure-report-publisher upload gitlab-artifacts`](#allure-report-publisher-upload-gitlab-artifacts)
* [`allure-report-publisher upload s3`](#allure-report-publisher-upload-s3)

## `allure-report-publisher upload gcs`

Generate and upload allure report to gcs bucket

```
USAGE
  $ allure-report-publisher upload gcs -b <value> [-r <value>] [-c <value>] [--report-name <value>] [-o <value>]
    [--global-allure-exec] [--ci-report-title <value>] [--update-pr comment|description|actions] [--add-summary]
    [--collapse-summary] [--flaky-warning-status] [--color] [--debug] [--ignore-missing-results] [-p <value>]
    [--base-url <value>] [--copy-latest] [--parallel <value>]

FLAGS
  -b, --bucket=<value>           (required) [env: ALLURE_BUCKET] Cloud storage bucket name
  -c, --config=<value>           [env: ALLURE_CONFIG] The path to allure config file. Options provided here will
                                 override CLI flags
  -o, --output=<value>           [env: ALLURE_OUTPUT] Directory to generate the Allure report into
  -p, --prefix=<value>           [env: ALLURE_PREFIX] Prefix for report path in cloud storage
  -r, --results-glob=<value>     [default: ./**/allure-results, env: ALLURE_RESULTS_GLOB] Glob pattern for allure
                                 results directories
      --add-summary              [env: ALLURE_SUMMARY] Add test summary table to section in PR
      --base-url=<value>         [env: ALLURE_BASE_URL] Custom base URL for report links
      --ci-report-title=<value>  [default: Allure Report, env: ALLURE_CI_REPORT_TITLE] Title for PR comment/description
                                 section
      --collapse-summary         [env: ALLURE_COLLAPSE_SUMMARY] Create collapsible summary section in PR
      --[no-]color               [env: ALLURE_COLOR] Force color output
      --copy-latest              [env: ALLURE_COPY_LATEST] Keep copy of latest run report at base prefix
      --debug                    [env: ALLURE_DEBUG] Print debug log output
      --flaky-warning-status     [env: ALLURE_FLAKY_WARNING_STATUS] Mark run with ! status if flaky tests found
      --global-allure-exec       [env: ALLURE_GLOBAL_ALLURE_EXEC] Use globally installed allure executable instead of
                                 the packaged one
      --ignore-missing-results   [env: ALLURE_IGNORE_MISSING_RESULTS] Ignore missing allure results and exit without
                                 error if no result paths found
      --parallel=<value>         [default: 8, env: ALLURE_PARALLEL] Number of parallel threads for upload
      --report-name=<value>      [env: ALLURE_REPORT_NAME] Custom report name in Allure report
      --update-pr=<option>       [env: ALLURE_UPDATE_PR] Update PR with a section containing the report URL
                                 <options: comment|description|actions>

DESCRIPTION
  Generate and upload allure report to gcs bucket

EXAMPLES
  $ allure-report-publisher upload gcs --results-glob="path/to/allure-results" --bucket=my-bucket

  $ allure-report-publisher upload gcs --results-glob="path/to/allure-results" --bucket=my-bucket --update-pr=comment --summary=behaviors
```

_See code: [src/commands/upload/gcs.ts](https://github.com/andrcuns/allure-report-publisher/blob/v5.0.1/src/commands/upload/gcs.ts)_

## `allure-report-publisher upload gitlab-artifacts`

Generate report and output GitLab CI artifacts links

```
USAGE
  $ allure-report-publisher upload gitlab-artifacts [-r <value>] [-c <value>] [--report-name <value>] [-o <value>]
    [--global-allure-exec] [--ci-report-title <value>] [--update-pr comment|description|actions] [--add-summary]
    [--collapse-summary] [--flaky-warning-status] [--color] [--debug] [--ignore-missing-results]

FLAGS
  -c, --config=<value>           [env: ALLURE_CONFIG] The path to allure config file. Options provided here will
                                 override CLI flags
  -o, --output=<value>           [env: ALLURE_OUTPUT] Directory to generate the Allure report into
  -r, --results-glob=<value>     [default: ./**/allure-results, env: ALLURE_RESULTS_GLOB] Glob pattern for allure
                                 results directories
      --add-summary              [env: ALLURE_SUMMARY] Add test summary table to section in PR
      --ci-report-title=<value>  [default: Allure Report, env: ALLURE_CI_REPORT_TITLE] Title for PR comment/description
                                 section
      --collapse-summary         [env: ALLURE_COLLAPSE_SUMMARY] Create collapsible summary section in PR
      --[no-]color               [env: ALLURE_COLOR] Force color output
      --debug                    [env: ALLURE_DEBUG] Print debug log output
      --flaky-warning-status     [env: ALLURE_FLAKY_WARNING_STATUS] Mark run with ! status if flaky tests found
      --global-allure-exec       [env: ALLURE_GLOBAL_ALLURE_EXEC] Use globally installed allure executable instead of
                                 the packaged one
      --ignore-missing-results   [env: ALLURE_IGNORE_MISSING_RESULTS] Ignore missing allure results and exit without
                                 error if no result paths found
      --report-name=<value>      [env: ALLURE_REPORT_NAME] Custom report name in Allure report
      --update-pr=<option>       [env: ALLURE_UPDATE_PR] Update PR with a section containing the report URL
                                 <options: comment|description|actions>

DESCRIPTION
  Generate report and output GitLab CI artifacts links
```

_See code: [src/commands/upload/gitlab-artifacts.ts](https://github.com/andrcuns/allure-report-publisher/blob/v5.0.1/src/commands/upload/gitlab-artifacts.ts)_

## `allure-report-publisher upload s3`

Generate and upload allure report to s3 bucket

```
USAGE
  $ allure-report-publisher upload s3 -b <value> [-r <value>] [-c <value>] [--report-name <value>] [-o <value>]
    [--global-allure-exec] [--ci-report-title <value>] [--update-pr comment|description|actions] [--add-summary]
    [--collapse-summary] [--flaky-warning-status] [--color] [--debug] [--ignore-missing-results] [-p <value>]
    [--base-url <value>] [--copy-latest] [--parallel <value>]

FLAGS
  -b, --bucket=<value>           (required) [env: ALLURE_BUCKET] Cloud storage bucket name
  -c, --config=<value>           [env: ALLURE_CONFIG] The path to allure config file. Options provided here will
                                 override CLI flags
  -o, --output=<value>           [env: ALLURE_OUTPUT] Directory to generate the Allure report into
  -p, --prefix=<value>           [env: ALLURE_PREFIX] Prefix for report path in cloud storage
  -r, --results-glob=<value>     [default: ./**/allure-results, env: ALLURE_RESULTS_GLOB] Glob pattern for allure
                                 results directories
      --add-summary              [env: ALLURE_SUMMARY] Add test summary table to section in PR
      --base-url=<value>         [env: ALLURE_BASE_URL] Custom base URL for report links
      --ci-report-title=<value>  [default: Allure Report, env: ALLURE_CI_REPORT_TITLE] Title for PR comment/description
                                 section
      --collapse-summary         [env: ALLURE_COLLAPSE_SUMMARY] Create collapsible summary section in PR
      --[no-]color               [env: ALLURE_COLOR] Force color output
      --copy-latest              [env: ALLURE_COPY_LATEST] Keep copy of latest run report at base prefix
      --debug                    [env: ALLURE_DEBUG] Print debug log output
      --flaky-warning-status     [env: ALLURE_FLAKY_WARNING_STATUS] Mark run with ! status if flaky tests found
      --global-allure-exec       [env: ALLURE_GLOBAL_ALLURE_EXEC] Use globally installed allure executable instead of
                                 the packaged one
      --ignore-missing-results   [env: ALLURE_IGNORE_MISSING_RESULTS] Ignore missing allure results and exit without
                                 error if no result paths found
      --parallel=<value>         [default: 8, env: ALLURE_PARALLEL] Number of parallel threads for upload
      --report-name=<value>      [env: ALLURE_REPORT_NAME] Custom report name in Allure report
      --update-pr=<option>       [env: ALLURE_UPDATE_PR] Update PR with a section containing the report URL
                                 <options: comment|description|actions>

DESCRIPTION
  Generate and upload allure report to s3 bucket

EXAMPLES
  $ allure-report-publisher upload s3 --results-glob="path/to/allure-results" --bucket=my-bucket

  $ allure-report-publisher upload s3 --results-glob="path/to/allure-results" --bucket=my-bucket --update-pr=comment --summary=behaviors
```

_See code: [src/commands/upload/s3.ts](https://github.com/andrcuns/allure-report-publisher/blob/v5.0.1/src/commands/upload/s3.ts)_
<!-- commandsstop -->

## Docker

Dockerized version of cli can be used by passing same arguments to `andrcuns/allure-report-publisher` image:

```sh-session
docker run --rm -it \
  -v ${PWD}:/app/data \
  -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
  -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
  andrcuns/allure-report-publisher:latest upload s3 --results-glob="/app/data/**/allure-results" --bucket=my-bucket
```

## Allure configuration file

It is possible to provide [Allure configuration file](https://allurereport.org/docs/v3/configure/) via `--config` flag. Dynamic javascript files are supported, but plain javascript object without the use of `defineConfig` is suggested due to `defineConfig` helper loading `allure` cli parser which will create error output.

# Storage providers

Multiple cloud storage providers are supported

## AWS S3

Requires environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` or credentials file `~/.aws/credentials`

Additional configuration:

* `AWS_REGION`: configure s3 region, default: `us-east-1`
* `AWS_FORCE_PATH_STYLE`: when set to true, the bucket name is always left in the request URI and never moved to the host as a sub-domain, default: `false`
* `AWS_ENDPOINT`: custom s3 endpoint when used with other s3 compatible storage

## Google Cloud Storage

GCS node.js client uses [ADC](https://docs.cloud.google.com/docs/authentication/application-default-credentials) to detect credentials. Easiest way is to set `GOOGLE_APPLICATION_CREDENTIALS` environment variable pointing to service account credentials.json file.

## Gitlab Artifacts

This storage provider is only supported for GitLab CI. Because GitLab does not expose public api for uploading artifacts, a job must be configured to upload the report as an artifact. Example:

```yaml
# .gitlab-ci.yml
artifacts:
  paths:
    - allure-report
```

where `allure-report` is the directory containing the generated Allure report and can be overridden via `--output` option.

Requires environment variable `GITLAB_AUTH_TOKEN` where token is a GitLab personal access token with `api` scope capable of downloading artifacts and retrieving job and pipeline information.

This provider is meant to be used with [GitLab CI](#gitlab-ci).

# CI

`allure-report-publisher` will automatically detect if used in CI environment and add relevant executor info and history.

Following CI providers are supported:

* Github Actions
* Gitlab CI

## Pull requests

It is possible to update pull requests with urls to published reports and execution summary.

* `--update-pr=(comment|description|actions)`: post report urls in pr description, as a comment or step summary for github actions

Example:

---

`# Allure report`

`allure-report-publisher` generated test report!

**test**: ✅ [test report](https://storage.googleapis.com/allure-test-reports/allure-report-publisher/refs/heads/main/index.html) for [1b756f48](https://github.com/andrcuns/allure-report-publisher/commit/HEAD)

```console
  +----------+----------+----------+----------+----------+----------+
  |  passed  |  failed  |  flaky   | retried  | skipped  |  total   |
  +----------+----------+----------+----------+----------+----------+
  |    69    |    0     |    0     |    0     |    0     |    69    |
  +----------+----------+----------+----------+----------+----------+
```

---

## Github Actions

Additional configuration is done via environment variables

Authentication for PR updates:

* `GITHUB_AUTH_TOKEN`: github auth token with api access

Following environment variables can override default CI values:

* `ALLURE_JOB_NAME`: overrides default `GITHUB_JOB` value which is used as name for report url section
* `ALLURE_RUN_ID`: overrides default `GITHUB_RUN_ID` value which is used as name for the run number

### allure-publish-action

[allure-publish-action](https://github.com/marketplace/actions/allure-publish-action) can be used to easily run report publishing from any github actions job.

## Gitlab CI

Additional configuration is done via environment variables

### Authentication

Authentication for MR updates:

* `GITLAB_AUTH_TOKEN`: gitlab access token with api access

### CI values

Following environment variables can override default CI values:

* `ALLURE_JOB_NAME`: overrides default `CI_JOB_NAME` value which is used as name for report url section
* `ALLURE_RUN_ID`: overrides default `CI_PIPELINE_ID` value which is used as name for the run number

In case merge request triggers a downstream pipeline yet you want to update original merge request, overriding following environment variables might be useful:

* `ALLURE_PROJECT_PATH`: overrides default `CI_PROJECT_PATH` value
* `ALLURE_MERGE_REQUEST_IID`: overrides default `CI_MERGE_REQUEST_IID` value
* `ALLURE_COMMIT_SHA`: overrides default `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA` or `CI_COMMIT_SHA` values

### CI/CD catalog resource

[allure-report-publisher CI/CD catalog resource](https://gitlab.com/andrcuns/allure-report-publisher) can be used to easily integrate report publishing in to Gitlab CI pipelines.

# Development

Local development tool are handled by [mise](https://mise.jdx.dev/). After checking out the repo, run `mise install` to install necessary dev tools. Run `pnpm install` to install all node dependencies. To run tests, use `pnpm run test`. `bin/dev.js` allows to execute the cli directly from the source code without building it first.

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/andrcuns/allure-report-publisher>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).

# License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Code of Conduct

Everyone interacting in the allure-report-publisher project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).
