#!/bin/bash

# AI Stack Management Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script info
SCRIPT_NAME="AI Stack Manager"
VERSION="1.0.0"

# Function to print colored output
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    echo -e "${BLUE}$SCRIPT_NAME v$VERSION${NC}"
    echo "Manage your AI Stack deployment"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo -e "  ${GREEN}start${NC}      Start all services"
    echo -e "  ${GREEN}stop${NC}       Stop all services"
    echo -e "  ${GREEN}restart${NC}    Restart all services"
    echo -e "  ${GREEN}status${NC}     Check service status"
    echo -e "  ${GREEN}logs${NC}       Show service logs"
    echo -e "  ${GREEN}clean${NC}      Clean up containers and volumes"
    echo -e "  ${GREEN}reset${NC}      Reset entire stack (destructive)"
    echo -e "  ${GREEN}models${NC}     Manage AI models"
    echo -e "  ${GREEN}backup${NC}     Backup data"
    echo -e "  ${GREEN}restore${NC}    Restore from backup"
    echo -e "  ${GREEN}update${NC}     Update services"
    echo -e "  ${GREEN}health${NC}     Run health checks"
    echo -e "  ${GREEN}shell${NC}      Access service shell"
    echo
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs backend"
    echo "  $0 models list"
    echo "  $0 shell ollama"
}

# Check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Start services
start_services() {
    print_header "Starting AI Stack Services"
    check_docker
    
    docker-compose up -d
    
    print_status "Services started. Checking health..."
    sleep 10
    check_health
}

# Stop services
stop_services() {
    print_header "Stopping AI Stack Services"
    check_docker
    
    docker-compose down
    print_status "All services stopped"
}

# Restart services
restart_services() {
    print_header "Restarting AI Stack Services"
    stop_services
    sleep 5
    start_services
}

# Check service status
check_status() {
    print_header "Service Status"
    check_docker
    
    echo "Docker Compose Services:"
    docker-compose ps
    
    echo -e "\nContainer Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# Show logs
show_logs() {
    print_header "Service Logs"
    check_docker
    
    if [ -z "$2" ]; then
        print_status "Showing logs for all services..."
        docker-compose logs -f --tail=50
    else
        print_status "Showing logs for $2..."
        docker-compose logs -f --tail=50 "$2"
    fi
}

# Clean up
clean_stack() {
    print_header "Cleaning Up AI Stack"
    
    read -p "This will remove containers but keep data. Continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down --remove-orphans
        docker system prune -f
        print_status "Cleanup completed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Reset stack (destructive)
reset_stack() {
    print_header "Resetting AI Stack"
    
    print_warning "This will DELETE ALL DATA including:"
    echo "- All containers"
    echo "- All volumes (databases, AI models)"
    echo "- All networks"
    echo
    read -p "Are you absolutely sure? Type 'RESET' to confirm: " -r
    echo
    if [[ $REPLY == "RESET" ]]; then
        docker-compose down -v --remove-orphans
        docker system prune -af --volumes
        print_status "Stack reset completed"
        print_status "Run './install.sh' to set up again"
    else
        print_status "Reset cancelled"
    fi
}

# Model management
manage_models() {
    check_docker
    
    case "$2" in
        "list"|"ls")
            print_header "Available AI Models"
            docker exec ollama ollama list 2>/dev/null || print_error "Ollama not running"
            ;;
        "pull")
            if [ -z "$3" ]; then
                print_error "Please specify model name: $0 models pull phi3"
                exit 1
            fi
            print_header "Pulling Model: $3"
            docker exec ollama ollama pull "$3"
            ;;
        "remove"|"rm")
            if [ -z "$3" ]; then
                print_error "Please specify model name: $0 models remove phi3"
                exit 1
            fi
            print_header "Removing Model: $3"
            docker exec ollama ollama rm "$3"
            ;;
        "run")
            if [ -z "$3" ]; then
                print_error "Please specify model name: $0 models run phi3"
                exit 1
            fi
            print_header "Testing Model: $3"
            docker exec -it ollama ollama run "$3" "Hello, please introduce yourself briefly."
            ;;
        "")
            print_header "Model Management"
            echo "Available commands:"
            echo "  models list     - List installed models"
            echo "  models pull <name>  - Pull/download a model"
            echo "  models remove <name> - Remove a model"
            echo "  models run <name>    - Test a model"
            ;;
        *)
            print_error "Unknown model command: $2"
            ;;
    esac
}

# Backup data
backup_data() {
    print_header "Creating Backup"
    
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    print_status "Backing up databases..."
    
    # Backup n8n database
    docker exec postgres pg_dump -U n8n n8n > "$BACKUP_DIR/n8n_backup.sql" 2>/dev/null || print_warning "n8n backup failed"
    
    # Backup application database
    docker exec postgres_backend pg_dump -U backend_user ai_app > "$BACKUP_DIR/app_backup.sql" 2>/dev/null || print_warning "App backup failed"
    
    # Backup n8n workflows and credentials
    docker cp n8n:/home/node/.n8n/workflows "$BACKUP_DIR/workflows" 2>/dev/null || print_warning "Workflows backup failed"
    
    # Create backup info
    echo "Backup created: $(date)" > "$BACKUP_DIR/backup_info.txt"
    echo "Stack version: $VERSION" >> "$BACKUP_DIR/backup_info.txt"
    
    print_status "Backup completed in: $BACKUP_DIR"
}

# Restore data
restore_data() {
    print_header "Restoring from Backup"
    
    if [ -z "$2" ]; then
        print_error "Please specify backup directory: $0 restore backups/20241201_120000"
        exit 1
    fi
    
    if [ ! -d "$2" ]; then
        print_error "Backup directory not found: $2"
        exit 1
    fi
    
    print_warning "This will overwrite current data!"
    read -p "Continue with restore? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Restore databases
        if [ -f "$2/n8n_backup.sql" ]; then
            docker exec -i postgres psql -U n8n n8n < "$2/n8n_backup.sql"
            print_status "n8n database restored"
        fi
        
        if [ -f "$2/app_backup.sql" ]; then
            docker exec -i postgres_backend psql -U backend_user ai_app < "$2/app_backup.sql"
            print_status "Application database restored"
        fi
        
        # Restore workflows
        if [ -d "$2/workflows" ]; then
            docker cp "$2/workflows" n8n:/home/node/.n8n/
            docker exec n8n chown -R node:node /home/node/.n8n/workflows
            print_status "Workflows restored"
        fi
        
        print_status "Restore completed"
        print_status "Restarting services..."
        restart_services
    else
        print_status "Restore cancelled"
    fi
}

# Update services
update_services() {
    print_header "Updating AI Stack Services"
    
    print_status "Pulling latest images..."
    docker-compose pull
    
    print_status "Rebuilding custom images..."
    docker-compose build --pull
    
    print_status "Restarting services..."
    docker-compose up -d
    
    print_status "Update completed"
}

# Health checks
check_health() {
    print_header "Health Check Results"
    
    # Check each service
    services=("frontend:3000" "backend:3001" "n8n:5678" "ollama:11434")
    
    for service in "${services[@]}"; do
        name="${service%:*}"
        port="${service#*:}"
        
        if curl -s "http://localhost:$port" > /dev/null 2>&1 || \
           curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            echo -e "✅ $name (port $port) - ${GREEN}Healthy${NC}"
        else
            echo -e "❌ $name (port $port) - ${RED}Unhealthy${NC}"
        fi
    done
    
    # Check database connections
    if docker exec postgres pg_isready -U n8n > /dev/null 2>&1; then
        echo -e "✅ PostgreSQL (n8n) - ${GREEN}Healthy${NC}"
    else
        echo -e "❌ PostgreSQL (n8n) - ${RED}Unhealthy${NC}"
    fi
    
    if docker exec postgres_backend pg_isready -U backend_user > /dev/null 2>&1; then
        echo -e "✅ PostgreSQL (backend) - ${GREEN}Healthy${NC}"
    else
        echo -e "❌ PostgreSQL (backend) - ${RED}Unhealthy${NC}"
    fi
}

# Access service shell
access_shell() {
    check_docker
    
    if [ -z "$2" ]; then
        print_error "Please specify service: $0 shell [ollama|n8n|backend|postgres]"
        exit 1
    fi
    
    case "$2" in
        "ollama")
            docker exec -it ollama bash
            ;;
        "n8n")
            docker exec -it n8n sh
            ;;
        "backend")
            docker exec -it ai_backend sh
            ;;
        "postgres")
            docker exec -it postgres psql -U n8n n8n
            ;;
        "postgres-backend")
            docker exec -it postgres_backend psql -U backend_user ai_app
            ;;
        *)
            print_error "Unknown service: $2"
            print_status "Available: ollama, n8n, backend, postgres, postgres-backend"
            ;;
    esac
}

# Main command handler
case "$1" in
    "start")
        start_services
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "status")
        check_status
        ;;
    "logs")
        show_logs "$@"
        ;;
    "clean")
        clean_stack
        ;;
    "reset")
        reset_stack
        ;;
    "models")
        manage_models "$@"
        ;;
    "backup")
        backup_data
        ;;
    "restore")
        restore_data "$@"
        ;;
    "update")
        update_services
        ;;
    "health")
        check_health
        ;;
    "shell")
        access_shell "$@"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac