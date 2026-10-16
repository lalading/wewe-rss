FROM node:20.16.0-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN npm i -g pnpm

FROM base AS build
COPY . /usr/src/app
WORKDIR /usr/src/app

RUN --mount=type=cache,id=s/e47ef8ae-ccaf-42a5-b111-0ba16331845e-pnpm,target=/pnpm/store pnpm install --no-frozen-lockfile

RUN pnpm run build:server
RUN pnpm run build:web



RUN pnpm deploy --filter=server --prod /app

RUN cd /app && pnpm exec prisma generate

RUN pnpm deploy --filter=server --prod /app-sqlite

RUN cd /app-sqlite && \
    rm -rf ./prisma && \
    mv prisma-sqlite prisma && \
    pnpm exec prisma generate




FROM base AS app-sqlite


WORKDIR /app

EXPOSE 4000

ENV NODE_ENV=production
ENV HOST="0.0.0.0"
ENV SERVER_ORIGIN_URL=""
ENV MAX_REQUEST_PER_MINUTE=60
ENV AUTH_CODE=""
ENV DATABASE_URL="file:../data/wewe-rss.db"
ENV DATABASE_TYPE="sqlite"

RUN chmod +x ./docker-bootstrap.sh

CMD ["/bin/sh", "-c", "npx prisma migrate deploy && node dist/main"]


FROM base AS app
COPY --from=build /app /app


COPY --from=build /usr/src/app/apps/server/client /app/client
WORKDIR /app

EXPOSE 4000

ENV NODE_ENV=production
ENV HOST="0.0.0.0"
ENV SERVER_ORIGIN_URL=""
ENV MAX_REQUEST_PER_MINUTE=60
ENV AUTH_CODE=""
ENV DATABASE_URL=""

RUN chmod +x ./docker-bootstrap.sh

CMD ["/bin/sh", "-c", "npx prisma migrate deploy && node dist/main"]
