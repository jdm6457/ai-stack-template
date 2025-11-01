# AI Stack Template

A complete, **fully automated**, self-hosted AI development stack with Ollama, n8n, React frontend, and Node.js backend.

## 🎯 What This Template Provides

- **🤖 Self-hosted AI**: Local LLM serving with Ollama (Phi-3 Mini, Llama2 7B)
- **🔄 Automated Workflow**: n8n workflow automatically imported and activated
- **💬 Chat Interface**: React-based frontend with real-time AI chat
- **🔌 REST API**: Node.js backend with PostgreSQL integration
- **📊 Example Integration**: Stock price lookup demo
- **🐳 Fully Containerized**: Complete Docker setup with one-command deployment
- **🔐 Secure by Default**: Pre-configured authentication and credentials

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- At least 8GB RAM (for AI models)
- 10GB free disk space
- Linux, macOS, or WSL2 (Windows)

### ⚡ One-Command Automated Setup

```bash
chmod +x quick-start.sh
./quick-start.sh
```

**That's it!** The script will:
1. ✅ Generate all project files and directories
2. ✅ Build and start all Docker containers
3. ✅ Wait for services to be healthy
4. ✅ **Automatically import and activate the n8n workflow**
5. ✅ Download AI models (Phi-3 Mini required, Llama2 optional)
6. ✅ Verify everything is working

**Total setup time:** 5-10 minutes (depending on internet speed for model downloads)

---

### 🔧 Manual Setup (Advanced)

If you prefer step-by-step control:

```bash
# 1. Generate project structure
chmod +x install.sh
./install.sh

# 2. Start all services
docker-compose up -d --build

# 3. Wait for services (2-3 minutes)
sleep 120

# 4. Setup AI models (interactive)
./scripts/setup-ollama.sh
```

**Note:** Manual setup requires manual n8n workflow import. See [Troubleshooting](#troubleshooting) section.

---

## 🔗 Access Points

Once deployment is complete:

| Service | URL | Credentials |
|---------|-----|-------------|
| **💬 Chat Interface** | http://localhost:3000 | None (open access) |
| **⚙️ n8n Workflows** | http://localhost:5678 | `admin@example.com` / `ChangeMe!1` |
| **🔌 Backend API** | http://localhost:3001 | None (API endpoints) |
| **🤖 Ollama API** | http://localhost:11434 | None (local access) |

---

## 🎨 Features

### AI Chat Interface
- **Multi-model Support**: Switch between Phi-3 Mini and Llama2 7B
- **Real-time Responses**: Stream-like experience via n8n webhooks
- **Conversation History**: All chats stored in PostgreSQL
- **Model Performance Indicators**: See which model was used for each response
- **Mobile Responsive**: Works on desktop, tablet, and mobile devices

### Stock Price Demo
- **Mock API Integration**: Example of external data integration
- **Historical Data**: Track price changes over time
- **Database Storage**: All queries stored for analysis
- **Real-time Updates**: Fetch latest prices on demand

### n8n Workflow Automation
- **Pre-configured Workflow**: Chat workflow automatically deployed
- **Production Webhooks**: Activated and ready to receive requests
- **Extensible**: Easy to add new workflows and integrations
- **Visual Editor**: Drag-and-drop workflow creation

---

## 📋 Project Structure

After running `install.sh`, the following structure is created:

```
ai-stack-template/
├── 📄 .gitignore                  # Git ignore rules (keeps repo clean)
├── 📄 .env                        # Environment variables (auto-generated)
├── 📄 .env.template               # Template for custom configurations
├── 📄 docker-compose.yml          # Service orchestration
├── 📄 README.md                   # This file
├── 📄 package.json                # Project metadata & npm scripts
├── 📄 n8n-workflow-chat.json      # Exportable n8n workflow
├── 📄 install.sh                  # Project structure generator ⚙️
├── 📄 quick-start.sh              # One-command deployment 🚀
├── 📄 manage.sh                   # Stack management utility 🛠️
│
├── 📁 backend/                    # Node.js Express API (generated)
│   ├── package.json              # Backend dependencies
│   ├── server.js                 # Main API server
│   ├── Dockerfile                # Backend container config
│   └── init.sql                  # Database schema & seed data
│
├── 📁 frontend/                   # React Application (generated)
│   ├── package.json              # Frontend dependencies
│   ├── Dockerfile                # Multi-stage build config
│   ├── nginx.conf                # Production web server config
│   ├── public/index.html         # HTML template
│   └── src/
│       ├── App.js                # Main React component
│       ├── App.css               # Application styles
│       └── index.js              # React entry point
│
├── 📁 n8n/workflows/              # n8n Workflows (generated)
│   └── chat-workflow.json        # Pre-configured chat workflow
│
└── 📁 scripts/                    # Utility Scripts (generated)
    └── setup-ollama.sh           # Interactive AI model downloader
```

**🔒 Files NOT committed to Git:**
- `backend/`, `frontend/`, `n8n/`, `scripts/` - Generated by install.sh
- `.env` - Contains secrets
- Docker volumes, logs, and data

---

## 🛠️ Management Commands

Use the management script for common operations:

```bash
# Service Management
./manage.sh start      # Start all services
./manage.sh stop       # Stop all services
./manage.sh restart    # Restart all services
./manage.sh status     # Check service status

# Monitoring
./manage.sh logs       # View all logs
./manage.sh logs n8n   # View specific service logs
./manage.sh health     # Run health checks

# AI Models
./manage.sh models list      # List installed models
./manage.sh models pull phi3 # Download a specific model
./manage.sh models run phi3  # Test a model

# Data Management
./manage.sh backup     # Create backup
./manage.sh restore    # Restore from backup
./manage.sh clean      # Remove containers (keep data)
./manage.sh reset      # Nuclear option - delete everything

# Access Service Shells
./manage.sh shell ollama    # Access Ollama container
./manage.sh shell n8n       # Access n8n container
./manage.sh shell backend   # Access backend container
./manage.sh shell postgres  # Access PostgreSQL
```

---

## 🔧 Configuration

### Default Credentials

**n8n Dashboard:**
- Email: `admin@example.com`
- Password: `ChangeMe!1`

**PostgreSQL Databases:**
- n8n DB: `n8n` / `n8n_password`
- Backend DB: `backend_user` / `backend_password`

⚠️ **Change these for production use!** Edit `.env` file after running `install.sh`.

### Environment Variables

The `.env` file (auto-generated) contains:

```bash
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_USER=admin@example.com
N8N_PASS=ChangeMe!1
N8N_EXTERNAL_API_USERS_ALLOW_BASIC_AUTH=true

# Database URLs
DATABASE_URL=postgresql://backend_user:backend_password@postgres_backend:5432/ai_app

# API Endpoints
N8N_WEBHOOK_URL=http://n8n:5678/webhook
REACT_APP_API_URL=http://localhost:3001

# Add your custom variables here
```

To customize:
1. Copy `.env.template` to `.env` (done automatically)
2. Edit values as needed
3. Restart services: `docker-compose down && docker-compose up -d`

---

## 🔄 Workflow Architecture

### Data Flow

```
User (Browser)
    ↓
Frontend (React:3000)
    ↓
Backend API (Node.js:3001)
    ↓
n8n Webhook (n8n:5678/webhook/chat)
    ↓
Ollama API (Ollama:11434/api/generate)
    ↓
AI Model Response
    ↓
Backend → Frontend → User
```

### n8n Workflow Components

The pre-configured workflow consists of 3 nodes:

1. **Webhook Node**
   - Path: `/webhook/chat`
   - Method: POST
   - Response Mode: Using 'Respond to Webhook' Node

2. **HTTP Request Node (Ollama)**
   - URL: `http://ollama:11434/api/generate`
   - Body: JSON with model, prompt, stream settings
   - Processes user message through AI model

3. **Respond to Webhook Node**
   - Returns formatted JSON response
   - Maps: response, model, chatId

**🔥 Fully Automated:** The workflow is automatically imported, activated, and verified during deployment!

---

## 🚀 Extending the Stack

### Adding New AI Models

```bash
# Method 1: Using manage script
./manage.sh models pull mistral:7b-instruct

# Method 2: Direct Ollama command
docker exec ollama ollama pull codellama:7b-instruct

# Method 3: During setup
# The setup-ollama.sh script offers interactive model selection
```

Available models: https://ollama.com/library

**After adding models:**
1. Update `frontend/src/App.js` model selector
2. Rebuild frontend: `docker-compose up -d --build frontend`

### Creating Custom Workflows

1. Access n8n: http://localhost:5678
2. Login with admin credentials
3. Create new workflow or duplicate existing
4. Add nodes (400+ integrations available)
5. Set webhook path (e.g., `/webhook/your-custom-path`)
6. Activate workflow
7. Update backend to call new webhook

### Adding API Endpoints

Edit `backend/server.js`:

```javascript
// Add new endpoint
app.post('/api/your-endpoint', async (req, res) => {
  const { data } = req.body;
  
  // Your logic here
  // Call n8n webhook if needed
  const n8nResponse = await axios.post(
    `${process.env.N8N_WEBHOOK_URL}/your-path`,
    { data }
  );
  
  res.json(n8nResponse.data);
});
```

Rebuild: `docker-compose up -d --build backend`

---

## 📊 Database Schema

### Backend Database (`ai_app`)

**Table: `chat_sessions`**
```sql
id          UUID PRIMARY KEY
user_message TEXT NOT NULL
ai_response TEXT
model_used  VARCHAR(100)
created_at  TIMESTAMP
updated_at  TIMESTAMP
```

**Table: `stock_prices`** (Example)
```sql
id             SERIAL PRIMARY KEY
symbol         VARCHAR(10) NOT NULL
price          DECIMAL(10,2)
change_amount  DECIMAL(10,2)
recorded_at    TIMESTAMP
```

Access database:
```bash
./manage.sh shell postgres-backend
# Then: SELECT * FROM chat_sessions ORDER BY created_at DESC LIMIT 10;
```

---

## 🔐 Security Considerations

### Development Setup (Current)
- ✅ Basic authentication enabled for n8n
- ✅ Local network only (no external access)
- ✅ Credentials in `.env` (gitignored)
- ⚠️ Mock data used (stock API example)

### Production Checklist
- [ ] Change all default passwords
- [ ] Enable HTTPS/SSL certificates
- [ ] Set up reverse proxy (Nginx, Traefik)
- [ ] Implement rate limiting
- [ ] Use secrets management (Docker secrets, Vault)
- [ ] Enable n8n API key authentication
- [ ] Configure firewall rules
- [ ] Set up monitoring and alerting
- [ ] Regular security updates
- [ ] Database backups (automated)

### Recommended Production Changes

Edit `.env`:
```bash
# Use strong, unique passwords
N8N_PASS=<generate-strong-password>
POSTGRES_PASSWORD=<generate-strong-password>

# Enable encryption
N8N_ENCRYPTION_KEY=<generate-32-char-key>

# Restrict access
CORS_ORIGIN=https://yourdomain.com
```

---

## 🐛 Troubleshooting

### Services Won't Start

```bash
# Check Docker status
docker info

# Check disk space
docker system df

# Check service logs
docker-compose logs

# Check specific service
docker-compose logs backend
```

### n8n Workflow Not Responding

**Symptoms:** Chat returns "No response received"

**Solutions:**

1. **Verify workflow is active:**
   ```bash
   # Check n8n logs for webhook registration
   docker-compose logs n8n | grep -i webhook
   ```

2. **Manual workflow activation:**
   - Go to http://localhost:5678
   - Open "AI Chat Workflow"
   - Toggle **Active** switch (top-right) to ON
   - Should turn green/blue

3. **Test webhook directly:**
   ```bash
   curl -X POST http://localhost:5678/webhook/chat \
     -H "Content-Type: application/json" \
     -d '{"message": "test", "model": "phi3:mini", "chatId": "test-123"}'
   ```

4. **Re-import workflow:**
   - Delete existing workflow in n8n
   - Import `n8n-workflow-chat.json` from project root
   - Activate it

### AI Models Not Loading

```bash
# Check if Ollama is running
docker-compose logs ollama

# List available models
docker exec ollama ollama list

# Re-download models
./scripts/setup-ollama.sh

# Test model directly
docker exec ollama ollama run phi3:mini "Hello"
```

### Frontend Can't Connect to Backend

```bash
# Check if backend is running
curl http://localhost:3001/health

# Check backend logs
docker-compose logs backend

# Verify network
docker network inspect ai-stack-template_ai_network

# Restart services
docker-compose restart backend frontend
```

### Database Connection Issues

```bash
# Check PostgreSQL status
docker exec postgres pg_isready -U n8n

# Check backend database
docker exec postgres_backend pg_isready -U backend_user

# Reset databases (⚠️ DELETES DATA)
docker-compose down -v
docker-compose up -d
```

### Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :3000  # or :5678, :3001, :11434

# Stop conflicting service
sudo systemctl stop <service-name>

# Or change port in docker-compose.yml
# Example: "3001:3001" → "3002:3001"
```

### Complete Reset

```bash
# Stop and remove everything
docker-compose down -v

# Remove generated files
rm -rf backend/ frontend/ n8n/ scripts/

# Start fresh
./quick-start.sh
```

---

## 📈 Performance Optimization

### For Development
```bash
# Allocate more RAM to Docker
# Docker Desktop: Settings → Resources → Memory → 8GB+

# Use faster storage
# Move Docker data to SSD if on HDD

# Reduce logging
# Edit docker-compose.yml:
# logging:
#   driver: "json-file"
#   options:
#     max-size: "10m"
#     max-file: "3"
```

### For Production
- Use managed PostgreSQL (AWS RDS, Google Cloud SQL)
- Implement Redis for session storage
- Enable Docker BuildKit for faster builds
- Use horizontal scaling for backend/frontend
- Set up CDN for frontend assets
- Implement caching strategies

---

## 🧪 Testing

### Test Backend API
```bash
# Health check
curl http://localhost:3001/health

# Chat endpoint
curl -X POST http://localhost:3001/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!", "model": "phi3:mini"}'

# Stock endpoint
curl http://localhost:3001/api/stock/AAPL
```

### Test n8n Webhook
```bash
curl -X POST http://localhost:5678/webhook/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Test", "model": "phi3:mini", "chatId": "test-123"}'
```

### Test Ollama API
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "phi3:mini", "prompt": "Hello", "stream": false}'
```

---

## 📚 Additional Resources

### Documentation
- [n8n Documentation](https://docs.n8n.io/)
- [Ollama Documentation](https://ollama.com/)
- [React Documentation](https://react.dev/)
- [Express.js Guide](https://expressjs.com/)
- [PostgreSQL Manual](https://www.postgresql.org/docs/)

### Useful Links
- [Ollama Model Library](https://ollama.com/library)
- [n8n Community Forum](https://community.n8n.io/)
- [Docker Documentation](https://docs.docker.com/)

### Model Performance Comparison

| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| **Phi-3 Mini** | 2.3GB | Fast ⚡ | Good ✓ | General chat, quick responses |
| **Llama2 7B** | 3.8GB | Medium | Better ✓✓ | Complex queries, detailed answers |
| **Mistral 7B** | 4.1GB | Medium | Better ✓✓ | Balanced performance |
| **CodeLlama 7B** | 3.8GB | Medium | Excellent ✓✓✓ | Code generation |

---

## 🤝 Contributing

This is a template project designed for customization. Feel free to:

- Fork and modify for your needs
- Share improvements and extensions
- Report issues or suggest features
- Create custom workflows and integrations

**Not actively accepting PRs** as this is a personal template, but ideas and feedback are welcome!

---

## 📝 License

This template is provided as-is for development and learning purposes. 

**Third-party components:**
- n8n: [Fair-code](https://faircode.io/) license
- Ollama: MIT License
- React: MIT License
- Express: MIT License
- PostgreSQL: PostgreSQL License

---

## 🎓 Learning Resources

### Beginners
1. Start with the Quick Start guide above
2. Explore the frontend code in `frontend/src/App.js`
3. Check backend API in `backend/server.js`
4. Play with n8n workflows at http://localhost:5678

### Intermediate
1. Add new endpoints to the backend
2. Create custom n8n workflows
3. Integrate external APIs (weather, news, etc.)
4. Implement user authentication

### Advanced
1. Set up production deployment
2. Implement RAG (Retrieval-Augmented Generation)
3. Create multi-agent workflows
4. Add model fine-tuning capabilities

---

## 💬 Support

**For issues with this template:**
- Check the [Troubleshooting](#troubleshooting) section
- Review logs: `docker-compose logs`
- Ensure prerequisites are met

**For component-specific issues:**
- n8n: https://community.n8n.io/
- Ollama: https://github.com/ollama/ollama/issues
- React: https://react.dev/community

---

## ✨ What's New

### Latest Updates
- ✅ **Fully automated n8n workflow import and activation**
- ✅ **One-command deployment** via `quick-start.sh`
- ✅ **Pre-configured authentication** for n8n
- ✅ **Health checks and wait logic** for reliable startup
- ✅ **Interactive model selection** during setup
- ✅ **Comprehensive management script** for operations
- ✅ **Production-ready Dockerfiles** with proper dependencies

### Roadmap
- [ ] Docker Hub images for faster deployment
- [ ] Kubernetes deployment manifests
- [ ] Terraform/Pulumi infrastructure as code
- [ ] CI/CD pipeline examples
- [ ] Additional pre-built workflows
- [ ] RAG implementation example
- [ ] User authentication system

---

**🚀 Ready to build amazing AI applications!**

Questions? Check the docs above or dive into the code. Happy coding! 🎉