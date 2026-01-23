FROM node:25.4.0-alpine3.23 AS node

# Build stage
#
FROM node AS build

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN npm install -g pnpm@latest-10

WORKDIR /build

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY ./ ./
RUN pnpm run build && pnpm prune --prod

# Production stage
#
FROM node AS production

# Create non-root user
RUN addgroup -g 1001 -S publisher && \
    adduser -u 1001 -S publisher -G publisher; \
    mkdir /app && chown publisher:publisher /app

ENV PATH="$PATH:/app/bin:/app/node_modules/.bin"

WORKDIR /app
USER publisher

COPY --chown=publisher:publisher ./bin/run.js ./bin/allure-report-publisher
COPY --chown=publisher:publisher ./package.json ./
COPY --from=build --chown=publisher:publisher /build/dist ./dist
COPY --from=build --chown=publisher:publisher /build/node_modules ./node_modules

# Verify installation
RUN allure-report-publisher --version

ENTRYPOINT [ "allure-report-publisher" ]
