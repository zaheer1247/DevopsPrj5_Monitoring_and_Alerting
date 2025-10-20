#!/bin/bash

# Start the monitoring stack using docker-compose or docker compose

set -e

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  COMPOSE_CMD="docker compose"
fi

echo "🚀 Starting Monitoring Stack..."
echo "Using: $COMPOSE_CMD"

$COMPOSE_CMD up -d

echo "⏳ Waiting for services to start (2-3 minutes)..."
sleep 5

echo "🔍 Checking service health..."

# Flask
if curl -sf http://localhost:5000/health >/dev/null; then
  echo "✅ Flask App is healthy"
else
  echo "⌛ Flask App not ready yet"
fi

# Prometheus
if curl -sf http://localhost:9090/-/healthy >/dev/null; then
  echo "✅ Prometheus is healthy"
else
  echo "⌛ Prometheus not ready yet"
fi

# Grafana
if curl -sf http://localhost:3000/api/health >/dev/null; then
  echo "✅ Grafana is healthy"
else
  echo "⌛ Grafana not ready yet"
fi

# Kibana
if curl -sf http://localhost:5601/api/status >/dev/null; then
  echo "✅ Kibana is healthy"
else
  echo "⌛ Kibana not ready yet"
fi

# Alertmanager
if curl -sf http://localhost:9093 >/dev/null; then
  echo "✅ Alertmanager is healthy"
else
  echo "⌛ Alertmanager not ready yet"
fi

echo "🎉 Done. Use ./status.sh to see details."


