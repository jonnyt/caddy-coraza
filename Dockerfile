FROM caddy:2.10.0-builder AS builder

WORKDIR /app
RUN xcaddy build --output caddy \
    --with github.com/corazawaf/coraza-caddy/v2@latest

FROM caddy:2.10.0 AS caddy-coraza

COPY --from=builder /app/caddy /usr/bin/caddy