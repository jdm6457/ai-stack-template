# AI Stack Template

A complete, self-hosted AI development stack with Ollama, n8n, React frontend, and Node.js backend.

## 🎯 What This Template Provides

- **🤖 Self-hosted AI**: Local LLM serving with Ollama (Phi-3, Llama2, etc.)
- **🔄 Workflow Automation**: n8n for AI workflow orchestration
- **💬 Chat Interface**: React-based frontend with real-time AI chat
- **🔌 REST API**: Node.js backend with PostgreSQL integration
- **📊 Example Integration**: Stock price lookup demo
- **🐳 Containerized**: Complete Docker setup with one-command deployment

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- At least 8GB RAM (for AI models)
- 10GB free disk space

### One-Command Setup
```bash
chmod +x quick-start.sh
./quick-start.sh
```

### Manual Setup
```bash
# 1. Generate project structure
chmod +x install.sh
./install.sh

# 2. Start all services
docker-compose up -d

# 3. Setup AI models (interactive)
./scripts/setup-ollama.sh
```

## 🔗 Access Points

Once running, access these services:

- **💬 Chat Interface**: http://localhost:3000
- **⚙️ n8n Workflows**: http://localhost:5678
- **🔌 Backend API**: http://localhost:3001
- **🤖 Ollama API**: http://localhost:11434

## 🛠️ Management

Use the management script for easy operations:

```bash
./manage.sh status    # Check all services
./manage.sh logs      # View logs
./manage.sh models    # Manage AI models
./manage.sh backup    # Create backups
./manage.sh clean     # Clean up containers
```

## 📋 What Gets Created

The install script generates:
```
ai-stack-template/
├── backend/          # Node.js API server
├── frontend/         # React chat application  
├── n8n/             # Workflow configurations
├── scripts/         # Utility scripts
└── docker-compose.yml # Service orchestration
```

## 🔧 Customization

### Adding New AI Models
```bash
./manage.sh models pull mistral:7b
# Then update frontend model selector
```

### Creating Custom Workflows
1. Visit http://localhost:5678
2. Create new workflow
3. Use webhook: `http://n8n:5678/webhook/your-path`

### Extending the API
Edit `backend/server.js` to add new endpoints and integrate with your workflows.

## 🎨 Example Features

- **Multi-model Chat**: Switch between different AI models
- **Conversation History**: Persistent chat storage
- **Stock Price Demo**: External API integration example
- **Real-time Responses**: WebSocket-like experience via n8n

## 🔒 Security Notes

⚠️ **This is a development template**

For production deployment:
- Enable authentication in n8n
- Use environment secrets management
- Implement rate limiting
- Add SSL/HTTPS
- Secure database access

## 📚 Documentation

- [Setup Guide](setup-n8n-credentials.md) - n8n credentials and configuration
- [Project Structure](project-structure.md) - Detailed architecture overview
- [API Documentation](http://localhost:3001/health) - Backend API reference

## 🐛 Troubleshooting

### Services Won't Start
```bash
docker-compose logs    # Check for errors
docker system df       # Check disk space
```

### Models Not Loading
```bash
./manage.sh models list     # Check installed models
docker logs ollama          # Check Ollama logs
```

### Reset Everything
```bash
./manage.sh reset    # Nuclear option - deletes all data
```

## 🤝 Contributing

This template is designed to be customized for your specific needs. Fork it, modify it, and build amazing AI applications!

## 📝 License

Open source template for development and learning purposes.# AI Stack Template

A complete, self-hosted AI development stack with Ollama, n8n, React frontend, and Node.js backend.

## 🎯 What This Template Provides

- **🤖 Self-hosted AI**: Local LLM serving with Ollama (Phi-3, Llama2, etc.)
- **🔄 Workflow Automation**: n8n for AI workflow orchestration
- **💬 Chat Interface**: React-based frontend with real-time AI chat
- **🔌 REST API**: Node.js backend with PostgreSQL integration
- **📊 Example Integration**: Stock price lookup demo
- **🐳 Containerized**: Complete Docker setup with one-command deployment

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- At least 8GB RAM (for AI models)
- 10GB free disk space

### One-Command Setup
```bash
chmod +x quick-start.sh
./quick-start.sh
```

### Manual Setup
```bash
# 1. Generate project structure
chmod +x install.sh
./install.sh

# 2. Start all services
docker-compose up -d

# 3. Setup AI models (interactive)
./scripts/setup-ollama.sh
```

## 📋 Importing the n8n Workflow

After starting the services:

1. Open n8n at http://localhost:5678
2. Click **"Workflows"** → **"Import from File"**  
3. Select `n8n-workflow-chat.json` from the project root
4. **Important**: Activate the workflow (toggle in top-right)
5. Test the chat at http://localhost:3000

The workflow connects: **Webhook → Ollama → Respond to Webhook**

## 🔗 Access Points

Once running, access these services:

- **💬 Chat Interface**: http://localhost:3000
- **⚙️ n8n Workflows**: http://localhost:5678
- **🔌 Backend API**: http://localhost:3001
- **🤖 Ollama API**: http://localhost:11434

## 🛠️ Management

Use the management script for easy operations:

```bash
./manage.sh status    # Check all services
./manage.sh logs      # View logs
./manage.sh models    # Manage AI models
./manage.sh backup    # Create backups
./manage.sh clean     # Clean up containers
```

## 📋 What Gets Created

The install script generates:
```
ai-stack-template/
├── backend/          # Node.js API server
├── frontend/         # React chat application  
├── n8n/             # Workflow configurations
├── scripts/         # Utility scripts
└── docker-compose.yml # Service orchestration
```

## 🔧 Customization

### Adding New AI Models
```bash
./manage.sh models pull mistral:7b
# Then update frontend model selector
```

### Creating Custom Workflows
1. Visit http://localhost:5678
2. Create new workflow
3. Use webhook: `http://n8n:5678/webhook/your-path`

### Extending the API
Edit `backend/server.js` to add new endpoints and integrate with your workflows.

## 🎨 Example Features

- **Multi-model Chat**: Switch between different AI models
- **Conversation History**: Persistent chat storage
- **Stock Price Demo**: External API integration example
- **Real-time Responses**: WebSocket-like experience via n8n

## 🔒 Security Notes

⚠️ **This is a development template**

For production deployment:
- Enable authentication in n8n
- Use environment secrets management
- Implement rate limiting
- Add SSL/HTTPS
- Secure database access

## 📚 Documentation

- [Setup Guide](setup-n8n-credentials.md) - n8n credentials and configuration
- [Project Structure](project-structure.md) - Detailed architecture overview
- [API Documentation](http://localhost:3001/health) - Backend API reference

## 🐛 Troubleshooting

### Services Won't Start
```bash
docker-compose logs    # Check for errors
docker system df       # Check disk space
```

### Models Not Loading
```bash
./manage.sh models list     # Check installed models
docker logs ollama          # Check Ollama logs
```

### Reset Everything
```bash
./manage.sh reset    # Nuclear option - deletes all data
```

## 🤝 Contributing

This template is designed to be customized for your specific needs. Fork it, modify it, and build amazing AI applications!

## 📝 License

Open source template for development and learning purposes.