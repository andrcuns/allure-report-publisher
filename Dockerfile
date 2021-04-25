FROM ruby:3.0.1-alpine3.13 as ruby

ARG GEMFILE=allure-report-publisher.gem

# Build stage
#
FROM ruby as build

ARG BUNDLER_VERSION=2.2.15
ARG BUNDLE_WITHOUT=development:test:release
ARG GEMFILE

RUN gem install bundler -N -v ${BUNDLER_VERSION} 

WORKDIR /build

# Copy dependency files needed for install first to fetch from cache if unchanged
COPY Gemfile Gemfile.lock allure-report-publisher.gemspec ./
COPY lib/allure_report_publisher/version.rb ./lib/allure_report_publisher/version.rb
COPY bin/allure-report-publisher bin/allure-report-publisher
RUN bundle install

COPY ./ ./
RUN gem build -o ${GEMFILE}

# Production stage
#
FROM ruby as production

# Install allure
ARG ALLURE_VERSION=2.13.9
ENV PATH=$PATH:/usr/local/allure-${ALLURE_VERSION}/bin
RUN apk --no-cache add openjdk11 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community
RUN set -eux; \
    wget https://repo.maven.apache.org/maven2/io/qameta/allure/allure-commandline/${ALLURE_VERSION}/allure-commandline-${ALLURE_VERSION}.tgz; \
    tar -xzf allure-commandline-${ALLURE_VERSION}.tgz -C /usr/local && rm allure-commandline-${ALLURE_VERSION}.tgz; \
    allure --version

# Install allure-report-publisher
ARG GEMFILE
COPY --from=build /build/${GEMFILE} ${GEMFILE}
RUN set -eux; \
    gem install -N ${GEMFILE} && rm ${GEMFILE}; \
    allure-report-publisher --version;

ENTRYPOINT [ "allure-report-publisher" ]
