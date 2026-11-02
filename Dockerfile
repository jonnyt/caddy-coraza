FROM caddy:2.11.7-builder AS builder

WORKDIR /app
RUN xcaddy build --output caddy \
    --with github.com/corazawaf/coraza-caddy/v2@v2.6.2

FROM caddy:2.11.7 AS caddy-coraza

COPY --from=builder /app/caddy /usr/bin/caddy