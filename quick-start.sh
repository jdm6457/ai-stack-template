#!/bin/bash
#!/bin/bash

# Ensure Unix line endings (fixes Windows CRLF issues)
set -e

# Convert line endings if running in WSL
if grep -q -i microsoft /proc/version 2>/dev/null || grep -q -i wsl /proc/version 2>/dev/null; then
    echo "🪟 WSL detected - ensuring proper line endings..."
    # Try dos2unix first, fall back to sed
    if command -v dos2unix &> /dev/null; then
        dos2unix "$0" 2>/dev/null || true
    else
        sed -i 's/\r$//' "$0" 2>/dev/null || true
    fi
    echo "✅ Line endings fixed"
fi

# Quick start script - runs everything in sequence
set -e

echo "🚀 AI Stack Quick Start (Automated Deployment)"
echo "==================================================="

# Run requirements check first
if [ -f "check-requirements.sh" ]; then
    echo -e "${BLUE}Running requirements check...${NC}"
    if ! ./check-requirements.sh; then
        echo -e "${RED}Requirements not met. Aborting.${NC}"
        exit 1
    fi
    echo ""
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- 1. Command Line Option Parsing ---
# Default mode is INTERACTIVE
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
# --------------------------------------

# Function to wait for a service's health endpoint
wait_for_service() {
    local service_name=$1
    local url=$2
    local attempts=20
    
    echo "Checking service health: $service_name"
    for i in $(seq 1 $attempts); do
        if curl -s $url > /dev/null 2>&1; then
            echo "✅ $service_name is ready"
            return 0
        fi
        echo "⏳ Waiting for $service_name..."
        sleep 5
    done
    echo "❌ $service_name failed to start."
    return 1
}

# --- Step 1: Setup ---
echo -e "${GREEN}Step 1: Setting up project structure...${NC}"
chmod +x install.sh
# Pass the LLAMA2_MODE to install.sh in case it's needed for README, though not essential here.
./install.sh

# --- Step 2: Start Services ---
echo -e "\n${GREEN}Step 2: Starting Docker services...${NC}"
docker-compose up -d --build

# --- Step 3: Wait for Health ---
echo -e "\n${GREEN}Step 3: Waiting for services to be ready...${NC}"
echo "This may take 2-3 minutes for first run..."
sleep 30

# Health checks for core services
wait_for_service "Backend" "http://localhost:3001/health"
wait_for_service "n8n" "http://localhost:5678"
wait_for_service "Ollama" "http://localhost:11434/api/tags"

# --- Step 3b: Importing and Activating n8n workflow via Database ---
echo -e "\n${GREEN}Step 3b: Importing and activating n8n workflow via Database...${NC}"

N8N_CONTAINER="n8n"
WORKFLOW_FILE_STAGING="/staging/initial_workflow.json"
N8N_DB_USER="n8n"
N8N_DB_NAME="n8n"

# 1. Wait for n8n to be fully responsive (Synchronization Gap Handling)
echo -e "${BLUE}Waiting for N8N container to establish database connection...${NC}"
for i in {1..20}; do
  # Check for the existence of the 'workflow_entity' table (Final Race Condition Fix)
  if docker exec postgres psql -U $N8N_DB_USER -d $N8N_DB_NAME -t -c "SELECT 1 FROM pg_tables WHERE tablename='workflow_entity';" > /dev/null 2>&1; then
    echo "✅ Postgres database schema is fully created."
    sleep 5 # Final safety delay before hitting the CLI
    break
  fi
  echo "⏳ Waiting for N8N to create schema ($i/20)..."
  sleep 5
  if [ $i -eq 20 ]; then
    echo -e "${RED}Error: N8N schema creation failed within the timeout period. Aborting.${NC}"
    exit 1
  fi
done


# 2. Import workflow using n8n CLI
echo -e "${BLUE}Importing workflow using n8n CLI...${NC}"
IMPORT_RESPONSE=$(docker exec -u node $N8N_CONTAINER n8n import:workflow --input=$WORKFLOW_FILE_STAGING 2>&1)

# Check for import success or conflict
if echo "$IMPORT_RESPONSE" | grep -q 'Successfully imported'; then
    echo "✅ Workflow imported successfully."
elif echo "$IMPORT_RESPONSE" | grep -q 'already exists in the database'; then
    echo "⚠️ Workflow already exists. Proceeding with activation."
else
    echo "$IMPORT_RESPONSE"
    echo -e "${RED}❌ FATAL ERROR: Workflow import failed (See message above). Aborting activation.${NC}"
    exit 1
fi


# 3. ID Retrieval Logic (CRITICAL: Database Query)
echo -e "${BLUE}Retrieving Workflow ID via direct database query (psql)...${NC}"

# Query the 'workflow_entity' table using the correct, case-sensitive column name.
QUERY="SELECT id FROM public.workflow_entity WHERE name='AI Chat Workflow' ORDER BY \"createdAt\" DESC LIMIT 1;"

RETRIEVED_ID=$(docker exec postgres psql -U $N8N_DB_USER -d $N8N_DB_NAME -t -c "$QUERY" | tr -d '[:space:]')

if [ -z "$RETRIEVED_ID" ]; then
    echo -e "${RED}❌ Error: Failed to retrieve Workflow ID from database. Aborting.${NC}"
    exit 1
fi
echo "Retrieved Workflow ID: $RETRIEVED_ID"


# 4. Activating the imported workflow
echo -e "${BLUE}Activating the imported workflow...${NC}"
docker exec -u node $N8N_CONTAINER n8n update:workflow --id=$RETRIEVED_ID --active=true

# 5. Restarting n8n service to apply activation changes (Mandatory CLI Step)
echo -e "${BLUE}Restarting n8n service to apply activation changes...${NC}"
docker-compose restart $N8N_CONTAINER

# 6. Wait for final restart and stability check
wait_for_service "n8n (Final Restart)" "http://localhost:5678"

# 7. CRITICAL: Re-run activation command to guarantee state after restart
echo -e "${BLUE}Final state check: Re-activating workflow (ID: $RETRIEVED_ID)...${NC}"
docker exec -u node $N8N_CONTAINER n8n update:workflow --id=$RETRIEVED_ID --active=true > /dev/null 2>&1

echo -e "${GREEN}✅ Deployment complete! Workflow ID $RETRIEVED_ID is now active. (Toggle will be ON).${NC}"

# --- Step 4: Ollama Models ---
echo -e "\n${GREEN}Step 4: Setting up AI models...${NC}"
# PASS THE MODE TO THE SETUP SCRIPT
./scripts/setup-ollama.sh "$LLAMA2_MODE"

# --- Completion ---
echo -e "\n${GREEN}🎉 Setup Complete!${NC}"
echo -e "\nYour AI stack is now running at:"
echo -e "• Frontend: ${YELLOW}http://localhost:3000${NC}"
echo -e "• n8n: ${YELLOW}http://localhost:5678${NC} (User: admin@example.com, Pass: ChangeMe!1)"
echo -e "• Backend API: ${YELLOW}http://localhost:3001${NC}"
echo -e "• Ollama API: ${YELLOW}http://localhost:11434${NC}"

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Open http://localhost:3000 to use the chat interface"
echo "2. Visit http://localhost:5678 to configure n8n workflows"
echo "3. Check the README.md for more configuration options"

echo -e "\nTo stop all services: ${YELLOW}docker-compose down${NC}"
echo -e "To view logs: ${YELLOW}docker-compose logs -f${NC}"