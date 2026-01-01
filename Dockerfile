FROM node:25.2.1-alpine3.23 AS node

FROM node AS pnpm

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN npm install -g pnpm@latest-10

WORKDIR /build

COPY package.json pnpm-lock.yaml ./

# Prod deps
#
FROM pnpm AS prod-deps

RUN pnpm install --frozen-lockfile --prod

# Build stage
#
FROM pnpm AS build

RUN pnpm install --frozen-lockfile

COPY ./ ./
RUN pnpm run build

# Production stage
#
FROM node AS production

WORKDIR /app

COPY ./bin/run.js ./bin/
COPY ./package.json ./

COPY --from=build /build/dist ./dist
COPY --from=prod-deps /build/node_modules ./node_modules

# Verify installation
RUN /app/bin/run.js --version

ENTRYPOINT [ "/app/bin/run.js" ]
