[![Gem Version](https://img.shields.io/gem/v/allure-report-publisher?color=red)](https://rubygems.org/gems/allure-report-publisher)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/andrcuns/allure-report-publisher?color=blue&label=docker&sort=semver)](https://hub.docker.com/r/andrcuns/allure-report-publisher)
![Workflow status](https://github.com/andrcuns/allure-report-publisher/workflows/Test/badge.svg)
[![Test Report](https://img.shields.io/badge/report-allure-blue.svg)](http://allure-reports-andrcuns.s3.amazonaws.com/allure-report-publisher/refs/heads/main/index.html)
[![Maintainability](https://api.codeclimate.com/v1/badges/210eaa4f74588fb08313/maintainability)](https://codeclimate.com/github/andrcuns/allure-report-publisher/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/210eaa4f74588fb08313/test_coverage)](https://codeclimate.com/github/andrcuns/allure-report-publisher/test_coverage)

# allure-report-publisher

Upload your report to a file storage of your choice.

![Demo](demo.gif)

## Installation

### Rubygems

```shell
gem install allure-report-uploader
```

### Docker

```shell
docker pull andrcuns/allure-report-publisher:latest
```

## Usage

allure-report-publisher will automatically detect if used in CI environment and add relevant executor info and history

- `Allure report link`: requires `GITHUB_AUTH_TOKEN` or `GITLAB_AUTH_TOKEN` in order to update pull request description with link to latest report

```shell
$ (allure-report-publisher|docker run --rm andrcuns/allure-report-publisher:latest) upload --help
Command:
  allure-report-publisher upload

Usage:
  allure-report-publisher upload TYPE

Description:
  Generate and upload allure report

Arguments:
  TYPE                 # REQUIRED Cloud storage type: (s3/gcs)

Options:
  --results-glob=VALUE             # Allure results files glob. Required: true
  --bucket=VALUE                   # Bucket name. Required: true
  --prefix=VALUE                   # Optional prefix for report path. Required: false
  --[no-]update-pr                 # Update pull request description with url to allure report, default: false
  --[no-]copy-latest               # Keep copy of latest report at base prefix path, default: false
  --[no-]color                     # Toggle color output, default: false
  --help, -h                       # Print this help

Examples:
  allure-report-publisher upload s3 --results-glob='path/to/allure-result/**/*' --bucket=my-bucket
  allure-report-publisher upload gcs --results-glob='path/to/allure-result/**/*' --bucket=my-bucket --prefix=my-project/prs
```

### AWS S3

- `AWS authentication`: requires environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` or credentials file `~/.aws/credentials`

### Google Cloud Storage

- `GCS authentication`: requires environment variable `GOOGLE_CLOUD_CREDENTIALS_JSON` with contents of credentials.json

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/andrcuns/allure-report-publisher>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the allure-report-publisher project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).
