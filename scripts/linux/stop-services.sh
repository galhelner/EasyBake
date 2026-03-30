#!/bin/bash
# Stop EasyBake services
echo "Stopping EasyBake services..."
cd "$(dirname "$0")/.."
docker compose down
echo "Services stopped."
