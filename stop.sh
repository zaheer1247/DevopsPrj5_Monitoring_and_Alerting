#!/bin/bash

exec "$(dirname "$0")/scripts/stop.sh" "$@"

#!/bin/bash

# Stop the monitoring stack using docker-compose or docker compose

set -e

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  COMPOSE_CMD="docker compose"
fi

echo "🛑 Stopping Monitoring Stack..."
echo "Using: $COMPOSE_CMD"

$COMPOSE_CMD down

echo "🗑️  Removing Flask application image..."
# Remove the Flask app image created by docker-compose build
docker rmi -f devops-flask-app 2>/dev/null || \
echo "ℹ️  Flask image not found or already removed"

echo "✅ Monitoring stack stopped and Flask image removed"