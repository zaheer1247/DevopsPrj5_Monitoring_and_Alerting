#!/bin/bash

# Universal Status Script for Windows/Mac/Linux

echo "🔍 Checking Monitoring Stack Status..."

# Use docker-compose or docker compose based on availability
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

echo "Using: $COMPOSE_CMD"
echo ""

# Show container status
echo "📦 Container Status:"
$COMPOSE_CMD ps

echo ""
echo "🌐 Service Health:"

services=(
    "Flask App:5000"
    "Prometheus:9090"
    "Grafana:3000"
    "Kibana:5601"
    "Alertmanager:9093"
)

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if curl -s -f http://localhost:$port > /dev/null 2>&1; then
        echo "✅ $name: Healthy (http://localhost:$port)"
    else
        echo "❌ $name: Unhealthy (http://localhost:$port)"
    fi
done

echo ""
echo "📊 Access URLs:"
echo "  Flask App:      http://localhost:5000"
echo "  Prometheus:     http://localhost:9090"
echo "  Grafana:        http://localhost:3000 (admin/admin)"
echo "  Kibana:         http://localhost:5601"
echo "  Alertmanager:   http://localhost:9093"


