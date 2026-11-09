FROM caddy:2.11.8-builder AS builder

WORKDIR /app
RUN xcaddy build --output caddy \
    --with github.com/corazawaf/coraza-caddy/v2@v2.6.2

FROM caddy:2.11.9 AS caddy-coraza

COPY --from=builder /app/caddy /usr/bin/caddy