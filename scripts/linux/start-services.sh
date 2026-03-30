#!/bin/bash
# Start EasyBake services in detached mode with rebuilds
echo "Starting EasyBake services..."
cd "$(dirname "$0")/.."
docker compose up -d --build
echo "Services started. Run 'docker compose ps' to check status."
