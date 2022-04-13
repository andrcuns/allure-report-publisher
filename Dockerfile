FROM ruby:3.1.2-alpine3.14 as ruby

ARG GEMFILE=allure-report-publisher.gem

# Build stage
#
FROM ruby as build

ARG BUNDLE_WITHOUT=development:test:release
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

# Install allure
ARG ALLURE_VERSION=2.17.2
ENV PATH=$PATH:/usr/local/allure-${ALLURE_VERSION}/bin
RUN apk --no-cache add openjdk11 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community
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
