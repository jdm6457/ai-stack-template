# AI Stack Project Structure

This document outlines the complete project structure and explains each component.

## 📁 Directory Structure
```
ai-stack-template/
├── 📄 docker-compose.yml          # Main orchestration file
├── 📄 .env                        # Environment variables
├── 📄 install.sh                  # Main installation script
├── 📄 quick-start.sh              # One-command setup
├── 📄 manage.sh                   # Stack management utility
├── 📄 README.md                   # Main documentation
├── 📄 setup-n8n-credentials.md    # n8n credentials guide
├── 📄 project-structure.md        # This file
├── 📄 package.json                # Project metadata
├── 📄 .env.template               # Environment template
├── 📄 .gitignore                  # Git ignore rules
│
├── 📁 backend/                    # Node.js API server (generated)
│   ├── 📄 package.json           # Node.js dependencies
│   ├── 📄 server.js              # Main server file
│   ├── 📄 Dockerfile             # Backend container config
│   └── 📄 init.sql               # Database initialization
│
├── 📁 frontend/                   # React application (generated)
│   ├── 📄 package.json           # React dependencies
│   ├── 📄 Dockerfile             # Frontend container config
│   ├── 📄 nginx.conf             # Nginx configuration
│   ├── 📁 public/
│   │   └── 📄 index.html         # HTML template
│   └── 📁 src/
│       ├── 📄 index.js           # React entry point
│       ├── 📄 App.js             # Main React component
│       ├── 📄 App.css            # Application styles
│       └── 📄 index.css          # Global styles
│
├── 📁 n8n/                       # n8n workflow automation (generated)
│   └── 📁 workflows/
│       └── 📄 chat-workflow.json # Pre-built chat workflow
│
└── 📁 scripts/                   # Utility scripts (generated)
    └── 📄 setup-ollama.sh        # AI model setup script
```

## 🔧 Component Details

### Root Level Files

#### `docker-compose.yml`
- **Purpose**: Orchestrates all services (Ollama, n8n, PostgreSQL, Frontend, Backend)
- **Services**: 6 containers with proper networking and volume management
- **Networks**: Custom bridge network for service communication
- **Volumes**: Persistent storage for databases and AI models

#### `.env`
- **Purpose**: Environment configuration for all services
- **Contains**: Database credentials, API URLs, service configurations
- **Security**: Should be customized for production use

#### `install.sh`
- **Purpose**: Automated setup script that creates entire project structure
- **Features**: 
  - Docker/Docker Compose validation
  - Complete file generation
  - Colored output and error handling
  - Comprehensive documentation generation

#### `quick-start.sh`
- **Purpose**: One-command deployment script
- **Process**: Runs install → starts services → waits for health → pulls models
- **Output**: Ready-to-use AI stack in minutes

### Backend (`backend/`)

#### Architecture
- **Framework**: Express.js (Node.js)
- **Database**: PostgreSQL with connection pooling
- **Features**: CORS enabled, JSON parsing, error handling

#### Key Endpoints
```javascript
GET  /health              # Health check
GET  /api/chats           # Chat history
POST /api/chat            # Send chat message
GET  /api/stock/:symbol   # Get stock price
GET  /api/stocks/:symbol/history # Stock history
```

#### Database Schema
```sql
-- Chat sessions
chat_sessions (id, user_message, ai_response, model_used, timestamps)

-- Stock prices (example data)
stock_prices (id, symbol, price, change_amount, recorded_at)
```

#### Docker Configuration
- **Base Image**: `node:18-alpine` (lightweight)
- **Build Process**: Multi-stage optimization
- **Port**: 3001 (internal and external)
- **Health Checks**: Built-in endpoint monitoring

### Frontend (`frontend/`)

#### Architecture
- **Framework**: React 18 with functional components
- **State Management**: React hooks (useState)
- **HTTP Client**: Axios for API communication
- **Build Tool**: Create React App

#### Key Features
- **Chat Interface**: Real-time messaging with AI models
- **Model Selection**: Switch between Phi-3 and Llama2
- **Stock Demo**: Example external API integration
- **Responsive Design**: Mobile-friendly layout
- **Loading States**: User feedback during API calls

#### Styling Approach
- **CSS**: Custom styles with modern design patterns
- **Layout**: Flexbox-based responsive design
- **Animations**: CSS keyframes for loading indicators
- **Theme**: Modern gradient design with clean typography

#### Production Build
- **Build Process**: Optimized production bundle
- **Web Server**: Nginx with reverse proxy configuration
- **Performance**: Minified assets, code splitting

### n8n Workflows (`n8n/`)

#### Pre-built Chat Workflow
```json
Webhook → Ollama API → Response
```

#### Workflow Components
1. **Webhook Trigger**: Receives POST requests on `/webhook/chat`
2. **Ollama Integration**: Sends prompts to local AI models
3. **Response Handler**: Returns formatted AI responses

#### Configuration
- **Database**: PostgreSQL for workflow storage
- **Authentication**: Disabled for development (configurable)
- **Webhooks**: Accessible at `http://localhost:5678/webhook/`

### Scripts (`scripts/`)

#### `setup-ollama.sh`
- **Purpose**: Downloads and configures AI models
- **Models**: 
  - Phi-3 Mini (3.8B parameters) - Fast, efficient
  - Llama 2 7B - More capable, slower
- **Health Checks**: Waits for Ollama service readiness
- **Testing**: Validates model installation

## 🏗️ Service Architecture

### Container Communication
```
Frontend (3000) ←→ Backend (3001) ←→ n8n (5678) ←→ Ollama (11434)
                         ↓
                  PostgreSQL (5432)
```

### Data Flow
1. **User Input**: Frontend captures user messages
2. **API Layer**: Backend validates and stores messages
3. **Workflow**: n8n processes requests via webhooks
4. **AI Processing**: Ollama generates responses
5. **Response**: Data flows back through the chain
6. **Storage**: Conversations stored in PostgreSQL

### Network Security
- **Internal Network**: All services on custom Docker network
- **Port Exposure**: Only necessary ports exposed to host
- **Service Discovery**: Container names used for internal communication

## 📊 Database Design

### n8n Database (postgres:n8n)
- **Purpose**: Stores workflows, credentials, execution history
- **Schema**: Managed automatically by n8n
- **Access**: Internal use only

### Application Database (postgres_backend:ai_app)
- **Purpose**: Application data storage
- **Tables**: 
  - `chat_sessions`: Conversation history
  - `stock_prices`: Example external data
- **Indexes**: Optimized for common queries

## 🔄 Development Workflow

### Local Development
1. **Code Changes**: Edit files in respective directories
2. **Container Rebuild**: `docker-compose build`
3. **Service Restart**: `docker-compose up -d`
4. **Log Monitoring**: `docker-compose logs -f`

### Adding Features
1. **Backend**: Add routes in `server.js`
2. **Frontend**: Add components in `src/`
3. **Workflows**: Create/modify in n8n interface
4. **Database**: Update `init.sql` for schema changes

### Testing
- **Backend**: Direct API testing via curl/Postman
- **Frontend**: Browser-based testing
- **Workflows**: n8n built-in testing tools
- **Integration**: Full stack testing through frontend

## 🚀 Deployment Options

### Development (Current)
- **Docker Compose**: Single machine deployment
- **Storage**: Local volumes
- **Security**: Minimal (development-focused)

### Production Considerations
- **Orchestration**: Kubernetes, Docker Swarm
- **Storage**: External databases, object storage
- **Security**: Authentication, HTTPS, secrets management
- **Monitoring**: Logging, metrics, health checks
- **Scaling**: Horizontal scaling for backend/frontend

## 📈 Performance Characteristics

### Resource Requirements
- **Minimum RAM**: 8GB (for AI models)
- **Storage**: 10GB+ (models + data)
- **CPU**: 4+ cores recommended
- **Network**: Low latency for real-time chat

### Optimization Strategies
- **AI Models**: Choose appropriate model sizes
- **Database**: Connection pooling, indexing
- **Frontend**: Code splitting, lazy loading
- **Caching**: Redis for session storage (future enhancement)

## 🔧 Customization Guide

### Adding New AI Models
1. **Ollama**: Pull model via `ollama pull model-name`
2. **Frontend**: Add to model selector options
3. **Backend**: Update model validation
4. **n8n**: Modify workflow to handle new model

### External API Integration
1. **Backend**: Add new endpoints
2. **Frontend**: Create UI components
3. **n8n**: Create workflows for external services
4. **Database**: Add tables for new data types

### UI Customization
1. **Styling**: Modify CSS files
2. **Components**: Edit React components
3. **Layout**: Update component structure
4. **Branding**: Update colors, fonts, logos

This structure provides a solid foundation for AI application development while remaining flexible for customization and scaling.