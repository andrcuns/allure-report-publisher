FROM ruby:3.4.5-alpine3.21 as ruby

ARG GEMFILE=allure-report-publisher.gem

# Build stage
#
FROM ruby as build

ARG BUNDLE_WITHOUT=development:release
ARG GEMFILE

WORKDIR /build

# Install build dependencies
RUN apk update && apk add --no-cache build-base

# Copy dependency files needed for install first to fetch from cache if unchanged
COPY Gemfile allure-report-publisher.gemspec ./
COPY lib/allure_report_publisher/version.rb ./lib/allure_report_publisher/version.rb
COPY exe/allure-report-publisher exe/allure-report-publisher
RUN bundle install

COPY ./ ./
RUN gem build -o ${GEMFILE}

# Production stage
#
FROM ruby as production

# Install allure
ARG ALLURE_VERSION=2.34.1
ENV PATH=$PATH:/usr/local/allure-${ALLURE_VERSION}/bin
RUN apk --no-cache add openjdk21 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community
RUN set -eux; \
    wget -O allure.tgz https://github.com/allure-framework/allure2/releases/download/${ALLURE_VERSION}/allure-${ALLURE_VERSION}.tgz; \
    tar -xzf allure.tgz -C /usr/local && rm allure.tgz; \
    allure --version

# Install allure-report-publisher
ARG GEMFILE
COPY --from=build /build/${GEMFILE} ${GEMFILE}
RUN set -eux; \
    gem install -N ${GEMFILE} && rm ${GEMFILE}; \
    allure-report-publisher --version;

ENTRYPOINT [ "allure-report-publisher" ]
