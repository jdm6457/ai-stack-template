# n8n Credentials Setup Guide

This guide explains how to set up credentials in n8n for various services and how to reuse existing credentials.

## 🔧 Basic Setup

### First Time Setup
1. Access n8n at `http://localhost:5678`
2. No authentication is required in development mode
3. The chat workflow should be automatically imported

### Importing Existing Workflows
If you have existing n8n workflows:
1. Go to Workflows → Import from File
2. Select your workflow JSON file
3. Save and activate the workflow

## 🔑 Credentials Management

### Creating New Credentials

#### Generic HTTP Auth
```
Name: Generic HTTP Auth
Type: HTTP Request Auth
Auth Type: Basic Auth / Bearer Token / OAuth2
```

#### OpenAI API (if you want to use GPT models)
```
Name: OpenAI
Type: OpenAI
API Key: your-openai-api-key
```

#### PostgreSQL Database
```
Name: PostgreSQL Backend
Type: Postgres
Host: postgres_backend
Port: 5432
Database: ai_app
User: backend_user
Password: backend_password
```

### Reusing Existing Credentials

#### Method 1: Export/Import
1. From your existing n8n instance:
   - Go to Settings → Credentials
   - Export credentials as JSON
2. In your new instance:
   - Go to Settings → Credentials
   - Import from JSON file

#### Method 2: Manual Recreation
1. Note down credential details from your existing setup
2. Recreate them manually in the new instance
3. Update workflow nodes to use the new credentials

#### Method 3: Database Migration (Advanced)
If both instances use PostgreSQL:
1. Export credentials table from source database
2. Import to target database
3. Update credential IDs in workflows if needed

## 🏢 Community License Setup

### n8n Community License
n8n is free for self-hosted use. For advanced features:

1. Visit [n8n.io](https://n8n.io) to get a license
2. In n8n Settings → License, enter your key
3. This unlocks:
   - Advanced nodes
   - Enhanced security features
   - Priority support

### Setting Environment Variables
Add to your `.env` file:
```bash
# n8n License
N8N_LICENSE_ACTIVATION_KEY=your-license-key

# Additional enterprise features
N8N_ENTERPRISE_LICENSE_ENABLED=true
```

## 🔐 Security Best Practices

### Development vs Production

**Development (Current Setup):**
- No authentication required
- Open access on localhost
- Suitable for testing and development

**Production Setup:**
Add these to your `.env`:
```bash
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-secure-password
N8N_JWT_SECRET=your-jwt-secret
```

### Credential Security
1. **Never commit credentials** to version control
2. **Use environment variables** for sensitive data
3. **Rotate credentials** regularly
4. **Use least privilege principle**

## 🔄 Common Credential Types

### REST API Services
```json
{
  "name": "External API",
  "type": "httpHeaderAuth",
  "data": {
    "headerAuth": {
      "name": "Authorization",
      "value": "Bearer YOUR_TOKEN"
    }
  }
}
```

### Database Connections
```json
{
  "name": "App Database",
  "type": "postgres",
  "data": {
    "host": "postgres_backend",
    "port": 5432,
    "database": "ai_app",
    "user": "backend_user",
    "password": "backend_password"
  }
}
```

## 🚀 Testing Credentials

### Quick Test Workflow
Create a simple test workflow:
1. Add HTTP Request node
2. Configure with your credentials
3. Test connection
4. Check response/error messages

### Debugging Connection Issues
1. Check container networking: `docker network ls`
2. Verify service connectivity: `docker exec n8n ping postgres_backend`
3. Check logs: `docker-compose logs n8n`
4. Validate credential parameters

## 🔧 Troubleshooting

### Common Issues

**Credential Not Found:**
- Ensure credential name matches exactly
- Check if credential is shared with workflow
- Verify credential type compatibility

**Connection Failures:**
- Test network connectivity between containers
- Verify service hostnames (use container names)
- Check firewall/security group settings

**Authentication Errors:**
- Validate credential parameters
- Check API key/token validity
- Verify authentication method requirements

### Reset Credentials
To completely reset n8n credentials:
```bash
docker-compose down
docker volume rm $(docker volume ls -q | grep n8n)
docker-compose up -d
```

## 📚 Additional Resources

- [n8n Credentials Documentation](https://docs.n8n.io/credentials/)
- [n8n Community Forum](https://community.n8n.io/)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)