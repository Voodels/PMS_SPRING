#!/usr/bin/env bash
set -euo pipefail

echo "Building and starting all services with docker-compose..."
docker-compose up -d --build

echo "Waiting for containers to report healthy..."
sleep 10

./health-check.sh || true

echo "Done. Use 'docker-compose logs -f' to follow logs."
