[![Gem Version](https://img.shields.io/gem/v/allure-report-publisher?color=red)](https://rubygems.org/gems/allure-report-publisher)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/andrcuns/allure-report-publisher?color=blue&label=docker&sort=semver)](https://hub.docker.com/r/andrcuns/allure-report-publisher)
![Workflow status](https://github.com/andrcuns/allure-report-publisher/workflows/Test/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/210eaa4f74588fb08313/maintainability)](https://codeclimate.com/github/andrcuns/allure-report-publisher/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/210eaa4f74588fb08313/test_coverage)](https://codeclimate.com/github/andrcuns/allure-report-publisher/test_coverage)

# allure-report-uploader

Upload your report to a file storage of your choice.

## Installation

```bash
gem install allure-report-uploader
```

## Usage

### AWS S3

```shell
$ allure-report-publisher upload s3 --help
Command:
  allure-report-publisher upload s3

Usage:
  allure-report-publisher upload s3

Description:
  Generate and upload allure report

Options:
  --result-files-glob=VALUE        # Allure results files glob. Required: true
  --bucket=VALUE                   # Bucket name. Required: true
  --project=VALUE                  # Project name for multiple reports inside single bucket. Required: false
  --help, -h                       # Print this help

Examples:
  allure-report-publisher upload s3 --result-files-glob='path/to/allure-result/**/*' --bucket=my-bucket
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/andrcuns/allure-report-publisher>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the allure-report-publisher project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/andrcuns/allure-report-publisher/blob/main/CODE_OF_CONDUCT.md).
