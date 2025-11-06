#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔍 AI Stack Requirements Checker"
echo "================================"

REQUIREMENTS_MET=true

# Check OS
check_os() {
    echo -e "\n${BLUE}Checking Operating System...${NC}"
    
    OS="$(uname -s)"
    case "$OS" in
        Linux*)
            echo -e "${GREEN}✅ Linux detected${NC}"
            OS_TYPE="Linux"
            ;;
        Darwin*)
            echo -e "${GREEN}✅ macOS detected${NC}"
            OS_TYPE="Mac"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo -e "${YELLOW}⚠️  Windows detected - WSL2 recommended${NC}"
            OS_TYPE="Windows"
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS: $OS${NC}"
            OS_TYPE="Unknown"
            REQUIREMENTS_MET=false
            ;;
    esac
}

# Check Docker
check_docker() {
    echo -e "\n${BLUE}Checking Docker...${NC}"
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        echo -e "${GREEN}✅ Docker installed: $DOCKER_VERSION${NC}"
        
        # Check if Docker is running
        if docker info &> /dev/null; then
            echo -e "${GREEN}✅ Docker daemon is running${NC}"
        else
            echo -e "${RED}❌ Docker is installed but not running${NC}"
            echo -e "${YELLOW}Start Docker with:${NC}"
            case "$OS_TYPE" in
                Linux)
                    echo "   sudo systemctl start docker"
                    ;;
                Mac)
                    echo "   Open Docker Desktop application"
                    ;;
                Windows)
                    echo "   Start Docker Desktop from Start Menu"
                    ;;
            esac
            REQUIREMENTS_MET=false
        fi
    else
        echo -e "${RED}❌ Docker not installed${NC}"
        echo -e "${YELLOW}Install Docker:${NC}"
        case "$OS_TYPE" in
            Linux)
                echo "   Ubuntu/Debian: https://docs.docker.com/engine/install/ubuntu/"
                echo "   Or run: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
                ;;
            Mac)
                echo "   Download Docker Desktop: https://docs.docker.com/desktop/install/mac-install/"
                echo "   Or with Homebrew: brew install --cask docker"
                ;;
            Windows)
                echo "   Download Docker Desktop: https://docs.docker.com/desktop/install/windows-install/"
                echo "   Requires WSL2: https://learn.microsoft.com/en-us/windows/wsl/install"
                ;;
        esac
        REQUIREMENTS_MET=false
    fi
}

# Check Docker Compose
check_docker_compose() {
    echo -e "\n${BLUE}Checking Docker Compose...${NC}"
    
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f4 | tr -d ',')
        echo -e "${GREEN}✅ Docker Compose installed: $COMPOSE_VERSION${NC}"
    elif docker compose version &> /dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version --short)
        echo -e "${GREEN}✅ Docker Compose (plugin) installed: $COMPOSE_VERSION${NC}"
    else
        echo -e "${RED}❌ Docker Compose not installed${NC}"
        echo -e "${YELLOW}Install Docker Compose:${NC}"
        case "$OS_TYPE" in
            Linux)
                echo "   sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
                echo "   sudo chmod +x /usr/local/bin/docker-compose"
                ;;
            Mac|Windows)
                echo "   Docker Compose is included with Docker Desktop"
                ;;
        esac
        REQUIREMENTS_MET=false
    fi
}

# Check RAM
check_ram() {
    echo -e "\n${BLUE}Checking System RAM...${NC}"
    
    case "$OS_TYPE" in
        Linux)
            TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
            ;;
        Mac)
            TOTAL_RAM=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
            ;;
        *)
            TOTAL_RAM="Unknown"
            ;;
    esac
    
    if [ "$TOTAL_RAM" != "Unknown" ]; then
        if [ "$TOTAL_RAM" -ge 8 ]; then
            echo -e "${GREEN}✅ RAM: ${TOTAL_RAM}GB (sufficient)${NC}"
        else
            echo -e "${YELLOW}⚠️  RAM: ${TOTAL_RAM}GB (8GB recommended)${NC}"
            echo -e "${YELLOW}   AI models may run slowly${NC}"
        fi
    fi
}

# Check Disk Space
check_disk() {
    echo -e "\n${BLUE}Checking Disk Space...${NC}"
    
    case "$OS_TYPE" in
        Linux|Mac)
            AVAILABLE=$(df -BG . | awk 'NR==2 {print $4}' | tr -d 'G')
            ;;
        *)
            AVAILABLE="Unknown"
            ;;
    esac
    
    if [ "$AVAILABLE" != "Unknown" ]; then
        if [ "$AVAILABLE" -ge 10 ]; then
            echo -e "${GREEN}✅ Disk space: ${AVAILABLE}GB available${NC}"
        else
            echo -e "${YELLOW}⚠️  Disk space: ${AVAILABLE}GB (10GB+ recommended)${NC}"
            echo -e "${YELLOW}   May not have enough space for AI models${NC}"
        fi
    fi
}

# Check Ports
check_ports() {
    echo -e "\n${BLUE}Checking Required Ports...${NC}"
    
    PORTS=(3000 3001 5678 11434)
    PORT_CONFLICTS=false
    
    for port in "${PORTS[@]}"; do
        if command -v lsof &> /dev/null; then
            if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
                echo -e "${YELLOW}⚠️  Port $port is in use${NC}"
                PORT_CONFLICTS=true
            else
                echo -e "${GREEN}✅ Port $port is available${NC}"
            fi
        elif command -v netstat &> /dev/null; then
            if netstat -tuln | grep -q ":$port "; then
                echo -e "${YELLOW}⚠️  Port $port is in use${NC}"
                PORT_CONFLICTS=true
            else
                echo -e "${GREEN}✅ Port $port is available${NC}"
            fi
        fi
    done
    
    if [ "$PORT_CONFLICTS" = true ]; then
        echo -e "${YELLOW}   You can change ports in docker-compose.yml${NC}"
    fi
}

# Check curl
check_curl() {
    echo -e "\n${BLUE}Checking curl...${NC}"
    
    if command -v curl &> /dev/null; then
        echo -e "${GREEN}✅ curl installed${NC}"
    else
        echo -e "${YELLOW}⚠️  curl not installed (needed for health checks)${NC}"
        case "$OS_TYPE" in
            Linux)
                echo "   Install: sudo apt-get install curl"
                ;;
            Mac)
                echo "   curl should be pre-installed"
                ;;
        esac
    fi
}

# Run all checks
check_os
check_docker
check_docker_compose
check_ram
check_disk
check_ports
check_curl

# Summary
echo -e "\n${BLUE}================================${NC}"
echo -e "${BLUE}Requirements Check Complete${NC}"
echo -e "${BLUE}================================${NC}\n"

if [ "$REQUIREMENTS_MET" = true ]; then
    echo -e "${GREEN}✅ All critical requirements met!${NC}"
    echo -e "${GREEN}You can proceed with installation.${NC}\n"
    echo -e "Run: ${YELLOW}./quick-start.sh${NC}"
    exit 0
else
    echo -e "${RED}❌ Some requirements are missing${NC}"
    echo -e "${YELLOW}Please install missing dependencies and try again.${NC}\n"
    
    echo -e "${BLUE}Quick Setup Guides:${NC}"
    echo -e "Ubuntu/Debian: https://docs.docker.com/engine/install/ubuntu/"
    echo -e "macOS: https://docs.docker.com/desktop/install/mac-install/"
    echo -e "Windows: https://docs.docker.com/desktop/install/windows-install/"
    
    exit 1
fi