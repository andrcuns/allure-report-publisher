FROM ruby:3.1.3-alpine3.15 as ruby

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

# Install allure
ARG ALLURE_VERSION=2.22.0
ENV PATH=$PATH:/usr/local/allure-${ALLURE_VERSION}/bin
RUN apk --no-cache add openjdk20 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
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
