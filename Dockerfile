FROM ruby:3.1.2-alpine3.15 as ruby

ARG GEMFILE=allure-report-publisher.gem

# Build stage
#
FROM ruby as build

ARG BUNDLE_WITHOUT=development:release
ARG GEMFILE

WORKDIR /build

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
    apk --no-cache add \
    openjdk17 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    python3

# Install gsutil
RUN set -eux; \
    wget -O /tmp/gsutil.tar.gz https://storage.googleapis.com/pub/gsutil.tar.gz; \
    tar -xzf /tmp/gsutil.tar.gz -C /usr/local; \
    ln -s /usr/local/gsutil/gsutil /usr/local/bin/gsutil; \
    rm -f /tmp/gsutil.tar.gz; \
    gsutil --version

# Install allure
ARG ALLURE_VERSION=2.19.0
ENV PATH=$PATH:/usr/local/allure-${ALLURE_VERSION}/bin
RUN set -eux; \
    wget https://github.com/allure-framework/allure2/releases/download/${ALLURE_VERSION}/allure-${ALLURE_VERSION}.tgz; \
    tar -xzf allure-${ALLURE_VERSION}.tgz -C /usr/local && rm allure-${ALLURE_VERSION}.tgz; \
    allure --version

# Install allure-report-publisher
ARG GEMFILE
COPY --from=build /build/${GEMFILE} ${GEMFILE}
RUN set -eux; \
    gem install -N ${GEMFILE} && rm ${GEMFILE}; \
    allure-report-publisher --version;

ENTRYPOINT [ "allure-report-publisher" ]
