#!/bin/bash

# Universal Logs Script for Windows/Mac/Linux

echo "📋 Showing Monitoring Stack Logs..."

# Use docker-compose or docker compose based on availability
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

echo "Using: $COMPOSE_CMD"
echo ""

# Show logs from all services
$COMPOSE_CMD logs -f


