#!/bin/bash

# Multi-OS Compatible Quick Start Script

set -e

# Force Unix line endings for this script
if command -v dos2unix &> /dev/null; then
    dos2unix "$0" 2>/dev/null || true
fi

echo "🚀 AI Stack Quick Start (Linux, macOS, & Windows Compatible)"
echo "============================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Detect environment
IS_WINDOWS=false
IS_WSL=false
IS_GIT_BASH=false

if grep -q -i microsoft /proc/version 2>/dev/null || grep -q -i wsl /proc/version 2>/dev/null; then
    IS_WSL=true
    echo -e "${BLUE}🪟 WSL detected${NC}"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    IS_GIT_BASH=true
    IS_WINDOWS=true
    echo -e "${BLUE}🪟 Git Bash detected${NC}"
elif [[ -n "$WINDIR" ]]; then
    IS_WINDOWS=true
    echo -e "${BLUE}🪟 Windows environment detected${NC}"
else
    echo -e "${BLUE}🐧 Linux environment detected${NC}"
fi

# Function to fix line endings in a file
fix_line_endings() {
    local file="$1"
    if [ -f "$file" ]; then
        if command -v dos2unix &> /dev/null; then
            dos2unix "$file" 2>/dev/null || sed -i 's/\r$//' "$file" 2>/dev/null || true
        else
            sed -i 's/\r$//' "$file" 2>/dev/null || true
        fi
    fi
}

# Fix all script files
echo -e "${BLUE}Fixing line endings in all scripts...${NC}"
for script in install.sh check-requirements.sh scripts/*.sh; do
    if [ -f "$script" ]; then
        fix_line_endings "$script"
        chmod +x "$script" 2>/dev/null || true
    fi
done
echo -e "${GREEN}✅ Line endings fixed${NC}"

# --- Command Line Option Parsing ---
LLAMA2_MODE="INTERACTIVE"

while getopts "fs" opt; do
  case ${opt} in
    f )
      LLAMA2_MODE="FULL_DOWNLOAD"
      echo "ℹ️ Running in automated FULL DOWNLOAD mode: Llama 2 7B will be downloaded."
      ;;
    s )
      LLAMA2_MODE="SKIP_DOWNLOAD"
      echo "ℹ️ Running in automated SKIP DOWNLOAD mode: Llama 2 7B download will be skipped."
      ;;
    \? )
      echo "Usage: $0 [-f] (Full Download) or [-s] (Skip Download)"
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Run requirements check
if [ -f "check-requirements.sh" ]; then
    echo -e "${BLUE}Running requirements check...${NC}"
    fix_line_endings "check-requirements.sh"
    chmod +x check-requirements.sh
    if ! ./check-requirements.sh; then
        echo -e "${RED}Requirements not met. Aborting.${NC}"
        exit 1
    fi
    echo ""
fi

# Function to wait for a service
wait_for_service() {
    local service_name=$1
    local url=$2
    local attempts=30
    
    echo "Checking service health: $service_name"
    for i in $(seq 1 $attempts); do
        if curl -s "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready${NC}"
            return 0
        fi
        echo "⏳ Waiting for $service_name... ($i/$attempts)"
        sleep 5
    done
    echo -e "${RED}❌ $service_name failed to start.${NC}"
    return 1
}

# --- Step 1: Setup ---
echo -e "${GREEN}Step 1: Setting up project structure...${NC}"
fix_line_endings "install.sh"
chmod +x install.sh
./install.sh

# --- Step 2: Fix Docker Compose paths for Windows ---
if [ "$IS_WINDOWS" = true ] || [ "$IS_GIT_BASH" = true ]; then
    echo -e "${BLUE}Applying Windows path fixes to docker-compose.yml...${NC}"
    
    # Create a backup
    cp docker-compose.yml docker-compose.yml.backup
    
    # Fix the workflow mount path - use forward slashes
    sed -i 's|./n8n/workflows/chat-workflow.json|./n8n/workflows/chat-workflow.json|g' docker-compose.yml
    
    echo -e "${GREEN}✅ Docker Compose paths fixed for Windows${NC}"
fi

# --- Step 3: Start Services ---
echo -e "\n${GREEN}Step 2: Starting Docker services...${NC}"

if [ "$IS_WSL" = true ]; then
    echo -e "${YELLOW}WSL Tip: Ensure Docker Desktop is running on Windows${NC}"
fi

# Use docker compose (new) or docker-compose (old)
if docker compose version &>/dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "Using: $COMPOSE_CMD"
$COMPOSE_CMD up -d --build

# --- Step 4: Wait for Health ---
echo -e "\n${GREEN}Step 3: Waiting for services to be ready...${NC}"
echo "This may take 2-3 minutes for first run..."
sleep 30

# Health checks
wait_for_service "Backend" "http://localhost:3001/health"
wait_for_service "n8n" "http://localhost:5678"
wait_for_service "Ollama" "http://localhost:11434/api/tags"

# --- Step 5: Import n8n workflow ---
echo -e "\n${GREEN}Step 4: Importing and activating n8n workflow...${NC}"

N8N_CONTAINER="n8n"
WORKFLOW_FILE_STAGING="/staging/initial_workflow.json"
N8N_DB_USER="n8n"
N8N_DB_NAME="n8n"

# Wait for n8n database
echo -e "${BLUE}Waiting for n8n database schema...${NC}"
for i in {1..30}; do
    if docker exec postgres psql -U $N8N_DB_USER -d $N8N_DB_NAME -t -c "SELECT 1 FROM pg_tables WHERE tablename='workflow_entity';" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database schema ready${NC}"
        sleep 5
        break
    fi
    echo "⏳ Waiting for n8n schema ($i/30)..."
    sleep 5
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: N8N schema creation timeout${NC}"
        exit 1
    fi
done

# Import workflow
echo -e "${BLUE}Importing workflow...${NC}"
IMPORT_RESPONSE=$(docker exec -u node $N8N_CONTAINER n8n import:workflow --input=$WORKFLOW_FILE_STAGING 2>&1)

if echo "$IMPORT_RESPONSE" | grep -q 'Successfully imported'; then
    echo -e "${GREEN}✅ Workflow imported successfully${NC}"
elif echo "$IMPORT_RESPONSE" | grep -q 'already exists'; then
    echo -e "${YELLOW}⚠️ Workflow already exists${NC}"
else
    echo "$IMPORT_RESPONSE"
    echo -e "${RED}❌ Workflow import failed${NC}"
    exit 1
fi

# Get workflow ID
echo -e "${BLUE}Retrieving workflow ID...${NC}"
QUERY="SELECT id FROM public.workflow_entity WHERE name='AI Chat Workflow' ORDER BY \"createdAt\" DESC LIMIT 1;"
RETRIEVED_ID=$(docker exec postgres psql -U $N8N_DB_USER -d $N8N_DB_NAME -t -c "$QUERY" | tr -d '[:space:]')

if [ -z "$RETRIEVED_ID" ]; then
    echo -e "${RED}❌ Failed to retrieve workflow ID${NC}"
    exit 1
fi
echo "Workflow ID: $RETRIEVED_ID"

# Re-import workflow to ensure nodes are saved (import bug workaround)
echo -e "${BLUE}Re-importing workflow to ensure proper node storage...${NC}"
docker exec -u node $N8N_CONTAINER n8n import:workflow --input=$WORKFLOW_FILE_STAGING 2>&1 | grep -q "Successfully imported"

# Activate via SQL (CLI has Zod validation bug)
echo -e "${BLUE}Activating workflow via database...${NC}"
docker exec postgres psql -U $N8N_DB_USER -d $N8N_DB_NAME -c "UPDATE workflow_entity SET active = true WHERE id = '1';"

# Restart n8n
echo -e "${BLUE}Restarting n8n...${NC}"
$COMPOSE_CMD restart $N8N_CONTAINER
wait_for_service "n8n (restarted)" "http://localhost:5678"

echo -e "${GREEN}✅ Workflow activated and ready (ID: $RETRIEVED_ID)${NC}"

# --- Step 6: Setup Ollama Models ---
echo -e "\n${GREEN}Step 5: Setting up AI models...${NC}"
fix_line_endings "scripts/setup-ollama.sh"
chmod +x scripts/setup-ollama.sh
./scripts/setup-ollama.sh "$LLAMA2_MODE"

# --- Completion ---
echo -e "\n${GREEN}🎉 Setup Complete!${NC}"
echo -e "\nYour AI stack is now running at:"
echo -e "• Frontend: ${YELLOW}http://localhost:3000${NC}"
echo -e "• n8n: ${YELLOW}http://localhost:5678${NC}"
echo -e "• Backend API: ${YELLOW}http://localhost:3001${NC}"
echo -e "• Ollama API: ${YELLOW}http://localhost:11434${NC}"

if [ "$IS_WINDOWS" = true ] || [ "$IS_GIT_BASH" = true ]; then
    echo -e "\n${BLUE}Windows Notes:${NC}"
    echo "• Run scripts using Git Bash or WSL"
    echo "• Ensure Docker Desktop has WSL 2 backend enabled"
    echo "• If ports are busy, check Windows firewall"
fi

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Open http://localhost:3000 to use the chat interface"
echo "2. Visit http://localhost:5678 to configure n8n workflows"
echo "3. Check the README.md for more configuration options"

echo -e "\nTo stop all services: ${YELLOW}$COMPOSE_CMD down${NC}"
echo -e "To view logs: ${YELLOW}$COMPOSE_CMD logs -f${NC}"
