#!/bin/bash

# Universal Setup Script for Windows/Mac/Linux
# This script works on all platforms with Docker

set -e

echo "🚀 Setting up Monitoring Stack for Windows/Mac/Linux..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    print_status "Detected OS: $OS"
}

# Check Docker
check_docker() {
    print_header "Checking Docker Installation"
    
    if command -v docker &> /dev/null; then
        print_status "Docker is installed"
        docker --version
    else
        print_error "Docker is not installed!"
        echo ""
        echo "Please install Docker from:"
        echo "  Windows/Mac: https://docker.com"
        echo "  Linux: https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    if command -v docker-compose &> /dev/null; then
        print_status "Docker Compose is installed"
        docker-compose --version
    else
        print_warning "Docker Compose not found, trying docker compose..."
        if docker compose version &> /dev/null; then
            print_status "Docker Compose (new version) is available"
        else
            print_error "Docker Compose is not available!"
            echo "Please install Docker Compose"
            exit 1
        fi
    fi
}

# Check if Docker is running
check_docker_running() {
    print_header "Checking Docker Status"
    
    if docker info &> /dev/null; then
        print_status "Docker is running"
    else
        print_error "Docker is not running!"
        echo ""
        echo "Please start Docker:"
        echo "  Windows/Mac: Start Docker Desktop"
        echo "  Linux: sudo systemctl start docker"
        exit 1
    fi
}

# Create directories
create_directories() {
    print_header "Creating Directories"
    
    mkdir -p logs
    mkdir -p data/prometheus
    mkdir -p data/grafana
    mkdir -p data/elasticsearch
    
    # Set directory and file permissions
    print_status "Setting logs directory permissions"
    sudo chmod 755 logs
    
    # Make shell scripts executable
    if [ -f "scripts/hiturl.sh" ]; then
        print_status "Making hiturl.sh executable"
        chmod +x scripts/hiturl.sh
    else
        print_warning "hiturl.sh not found, skipping executable setup"
    fi
    
    if [ -f "scripts/loop.sh" ]; then
        print_status "Making loop.sh executable"
        chmod +x scripts/loop.sh
    else
        print_warning "loop.sh not found, skipping executable setup"
    fi
    
    # Set filebeat.yml permissions and ownership
    if [ -f "config/logging/filebeat.yml" ]; then
        print_status "Setting filebeat.yml permissions and ownership"
        sudo chmod 644 config/logging/filebeat.yml
        sudo chown root:root config/logging/filebeat.yml
    else
        print_warning "filebeat.yml not found, skipping permission setup"
    fi
    
    print_status "Directories created successfully"
}

# Check ports
check_ports() {
    print_header "Checking Required Ports"
    
    ports=(3000 5000 5601 8080 9090 9093 9200)
    available=true
    
    for port in "${ports[@]}"; do
        if lsof -i :$port &> /dev/null || netstat -an | grep ":$port " &> /dev/null; then
            print_warning "Port $port is already in use"
            available=false
        else
            print_status "Port $port is available"
        fi
    done
    
    if [ "$available" = false ]; then
        print_warning "Some ports are in use. The stack might not work properly."
        echo "Please stop the services using these ports or change the port configuration."
    fi
}

# Start the stack
start_stack() {
    print_header "Starting Monitoring Stack"
    
    # Use docker-compose or docker compose based on availability
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    print_status "Using: $COMPOSE_CMD"
    
    # Start the stack
    $COMPOSE_CMD up -d
    
    print_status "Stack started successfully!"
}

# Wait for services
wait_for_services() {
    print_header "Waiting for Services to Start"
    
    print_status "Waiting for services to be ready (this may take 2-3 minutes)..."
    
    # Wait for Flask app
    for i in {1..30}; do
        if curl -s http://localhost:5000/health &> /dev/null; then
            print_status "✅ Flask app is ready"
            break
        fi
        echo -n "."
        sleep 10
    done
    
    # Wait for Prometheus
    for i in {1..30}; do
        if curl -s http://localhost:9090/-/healthy &> /dev/null; then
            print_status "✅ Prometheus is ready"
            break
        fi
        echo -n "."
        sleep 10
    done
    
    # Wait for Grafana
    for i in {1..30}; do
        if curl -s http://localhost:3000/api/health &> /dev/null; then
            print_status "✅ Grafana is ready"
            break
        fi
        echo -n "."
        sleep 10
    done
    
    echo ""
}

# Show status
show_status() {
    print_header "Service Status"
    
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
            echo -e "✅ $name: ${GREEN}Running${NC} (http://localhost:$port)"
        else
            echo -e "❌ $name: ${RED}Not responding${NC} (http://localhost:$port)"
        fi
    done
}

# Show access URLs
show_urls() {
    print_header "Access URLs"
    echo ""
    echo "🌐 Web Interfaces:"
    echo "  Flask App:      http://localhost:5000"
    echo "  Prometheus:     http://localhost:9090"
    echo "  Grafana:        http://localhost:3000 (admin/admin)"
    echo "  Kibana:         http://localhost:5601"
    echo "  Alertmanager:   http://localhost:9093"
    echo ""
    echo "🧪 Test Commands:"
    echo "  curl http://localhost:5000/health"
    echo "  curl http://localhost:5000/metrics"
    echo "  curl http://localhost:5000/may-fail"
    echo "  curl http://localhost:5000/generate-logs"
    echo ""
    echo "📊 Management Commands:"
    echo "  ./start.sh      - Start the stack"
    echo "  ./stop.sh       - Stop the stack"
    echo "  ./status.sh     - Check status"
    echo "  ./logs.sh       - View logs"
}

# Main execution
main() {
    print_header "Universal Monitoring Stack Setup"
    echo "This script works on Windows, Mac, and Linux"
    echo ""
    
    detect_os
    check_docker
    check_docker_running
    create_directories
    check_ports
    
    echo ""
    read -p "Do you want to start the monitoring stack now? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_stack
        wait_for_services
        show_status
        show_urls
        
        echo ""
        print_status "🎉 Setup completed successfully!"
        echo "The monitoring stack is now running."
        echo "Check the URLs above to access the services."
    else
        print_status "Setup completed. Run ./start.sh to start the stack."
    fi
}

# Run main function
main "$@"

