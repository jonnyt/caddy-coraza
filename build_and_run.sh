#!/bin/bash

set -e

IMAGE_NAME="caddy-coraza:latest"

echo "Building Caddy with Coraza..."
docker buildx build --platform linux/amd64,linux/arm64 -t $IMAGE_NAME .

echo "Running Caddy..."
docker run --rm -it \
    -p 80:80 -p 443:443 \
    -v $(pwd)/Caddyfile:/etc/caddy/Caddyfile \
    -v $(pwd)/coraza.conf:/etc/caddy/coraza.conf \
    $IMAGE_NAME
