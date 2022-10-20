FROM ruby:3.1.2-slim-bullseye as ruby

ARG GEMFILE=allure-report-publisher.gem

# Build stage
#
FROM ruby as build

ARG BUNDLE_WITHOUT=development:release
ARG GEMFILE

RUN set -eux; \
    apt-get update && apt-get install --no-install-recommends -y \
    wget \
    gcc \
    python3 \
    python3-pip \
    python3-dev \
    python3-setuptools

WORKDIR /build

RUN set -eux; \
    pip3 uninstall crcmod && pip3 install --no-cache-dir -U crcmod; \
    wget -O gsutil.tar.gz https://storage.googleapis.com/pub/gsutil.tar.gz; \
    tar -xzf gsutil.tar.gz

# Install allure
ARG ALLURE_VERSION=2.19.0
RUN set -eux; \
    wget -O allure.tgz https://github.com/allure-framework/allure2/releases/download/${ALLURE_VERSION}/allure-${ALLURE_VERSION}.tgz; \
    tar -xzf allure.tgz ; \
    mv allure-${ALLURE_VERSION} allure

# Copy dependency files needed for install first to fetch from cache if unchanged
COPY Gemfile allure-report-publisher.gemspec ./
COPY lib/allure_report_publisher/version.rb ./lib/allure_report_publisher/version.rb
COPY bin/allure-report-publisher bin/allure-report-publisher
RUN bundle install

COPY ./ ./
RUN gem build -o ${GEMFILE}

# Production stage
#
FROM ruby as production

# Install system libs
RUN set -eux; \
    apt-get update && apt-get install --no-install-recommends -y \
    openjdk-17-jdk-headless \
    python3

# Install gsutil
COPY --from=build /build/gsutil /usr/local/gsutil
COPY --from=build /usr/local/lib/python3.9/dist-packages /usr/local/lib/python3.9/dist-packages
RUN set -eux; \
    ln -s /usr/local/gsutil/gsutil /usr/local/bin/gsutil; \
    gsutil version -l

# Install allure
COPY --from=build /build/allure /usr/local/allure
RUN set -eux; \
    ln -s /usr/local/allure/bin/allure /usr/local/bin/allure; \
    allure --version

# Install allure-report-publisher
ARG GEMFILE
COPY --from=build /build/${GEMFILE} ${GEMFILE}
RUN set -eux; \
    gem install -N ${GEMFILE} && rm ${GEMFILE}; \
    allure-report-publisher --version;

ENTRYPOINT [ "allure-report-publisher" ]
