#!/bin/bash

# Quick start script - runs everything in sequence
set -e

echo "🚀 AI Stack Quick Start"
echo "======================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Step 1: Setting up project structure...${NC}"
chmod +x install.sh
./install.sh

echo -e "\n${GREEN}Step 2: Starting Docker services...${NC}"
docker-compose up -d

echo -e "\n${GREEN}Step 3: Waiting for services to be ready...${NC}"
echo "This may take 2-3 minutes for first run..."

# Wait for services to be healthy
sleep 30

# Check if services are running
echo "Checking service health..."
for i in {1..20}; do
    if curl -s http://localhost:3001/health > /dev/null 2>&1; then
        echo "✅ Backend is ready"
        break
    fi
    echo "⏳ Waiting for backend..."
    sleep 5
done

for i in {1..20}; do
    if curl -s http://localhost:5678 > /dev/null 2>&1; then
        echo "✅ n8n is ready"
        break
    fi
    echo "⏳ Waiting for n8n..."
    sleep 5
done

for i in {1..20}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama is ready"
        break
    fi
    echo "⏳ Waiting for Ollama..."
    sleep 5
done

echo -e "\n${GREEN}Step 4: Setting up AI models...${NC}"
./scripts/setup-ollama.sh

echo -e "\n${GREEN}🎉 Setup Complete!${NC}"
echo -e "\nYour AI stack is now running at:"
echo -e "• Frontend: ${YELLOW}http://localhost:3000${NC}"
echo -e "• n8n: ${YELLOW}http://localhost:5678${NC}" 
echo -e "• Backend API: ${YELLOW}http://localhost:3001${NC}"
echo -e "• Ollama API: ${YELLOW}http://localhost:11434${NC}"

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Open http://localhost:3000 to use the chat interface"
echo "2. Visit http://localhost:5678 to configure n8n workflows"
echo "3. Check the README.md for more configuration options"

echo -e "\nTo stop all services: ${YELLOW}docker-compose down${NC}"
echo -e "To view logs: ${YELLOW}docker-compose logs -f${NC}"