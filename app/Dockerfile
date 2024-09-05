FROM node:20-alpine AS base

RUN apk add openssl curl --no-cache

ENV TINI_VERSION=v0.19.0
RUN arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) \
 && curl -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${arch} -o /tini \
 && chmod +x /tini
ENTRYPOINT ["/tini", "--"]

FROM base AS build
WORKDIR /build
COPY . .
RUN npm ci \
 && npx prisma generate

FROM base AS runtime
ENV NODE_ENV=production \
    ENVIRONMENT=production

WORKDIR /app
COPY . . 
COPY --from=build /build/node_modules ./node_modules
RUN chmod +x ./entrypoint.sh \
 && chown -R node:node /app

USER node
CMD [ "./entrypoint.sh" ]