#!/bin/bash

set -e

echo "🚀 AI Stack Setup Script"
echo "========================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Check if Docker is installed
check_docker() {
    print_header "Checking Docker Installation"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_status "Docker is installed and running"
}

# Check if Docker Compose is installed
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_status "Docker Compose is installed"
}

# Create project structure
create_structure() {
    print_header "Creating Project Structure"
    
    mkdir -p {backend,frontend,n8n/workflows,scripts}
    print_status "Project directories created"
}

# Setup backend
setup_backend() {
    print_header "Setting up Backend"
    
    cat > backend/package.json << 'EOF'
{
  "name": "ai-backend",
  "version": "1.0.0",
  "description": "Backend for AI Stack",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3",
    "axios": "^1.6.0",
    "dotenv": "^16.3.1",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
EOF

    cat > backend/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://backend_user:backend_password@postgres_backend:5432/ai_app'
});

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Get chat history
app.get('/api/chats', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM chat_sessions ORDER BY created_at DESC LIMIT 50'
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching chats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create new chat session
app.post('/api/chat', async (req, res) => {
  const { message, model = 'phi3' } = req.body;
  
  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }

  try {
    // Store user message
    const chatId = uuidv4();
    await pool.query(
      'INSERT INTO chat_sessions (id, user_message, model_used) VALUES ($1, $2, $3)',
      [chatId, message, model]
    );

    // Send to n8n webhook
    const n8nResponse = await axios.post(`${process.env.N8N_WEBHOOK_URL}/chat`, {
      message: message,
      model: model,
      chatId: chatId
    });

    // Update with AI response
    await pool.query(
      'UPDATE chat_sessions SET ai_response = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [n8nResponse.data.response || 'No response', chatId]
    );

    res.json({
      chatId: chatId,
      response: n8nResponse.data.response || 'No response received',
      model: model
    });

  } catch (error) {
    console.error('Error processing chat:', error);
    res.status(500).json({ 
      error: 'Failed to process chat',
      details: error.message 
    });
  }
});

// Get stock price (example endpoint)
app.get('/api/stock/:symbol', async (req, res) => {
  const { symbol } = req.params;
  
  try {
    // Mock stock data - in production, use a real API like Alpha Vantage
    const mockPrice = (Math.random() * 1000 + 50).toFixed(2);
    const mockChange = (Math.random() * 20 - 10).toFixed(2);
    
    const stockData = {
      symbol: symbol.toUpperCase(),
      price: parseFloat(mockPrice),
      change: parseFloat(mockChange),
      timestamp: new Date().toISOString()
    };

    // Store in database
    await pool.query(
      'INSERT INTO stock_prices (symbol, price, change_amount, recorded_at) VALUES ($1, $2, $3, $4)',
      [stockData.symbol, stockData.price, stockData.change, stockData.timestamp]
    );

    res.json(stockData);
  } catch (error) {
    console.error('Error fetching stock:', error);
    res.status(500).json({ error: 'Failed to fetch stock data' });
  }
});

// Get stock history
app.get('/api/stocks/:symbol/history', async (req, res) => {
  const { symbol } = req.params;
  
  try {
    const result = await pool.query(
      'SELECT * FROM stock_prices WHERE symbol = $1 ORDER BY recorded_at DESC LIMIT 20',
      [symbol.toUpperCase()]
    );
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching stock history:', error);
    res.status(500).json({ error: 'Failed to fetch stock history' });
  }
});

// Initialize database tables
const initDatabase = async () => {
  try {
    await pool.query('SELECT 1');
    console.log('Database connected successfully');
  } catch (error) {
    console.error('Database connection failed:', error);
    setTimeout(initDatabase, 5000); // Retry after 5 seconds
  }
};

app.listen(port, () => {
  console.log(`Backend server running on port ${port}`);
  initDatabase();
});
EOF

    cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3001

CMD ["npm", "start"]
EOF

    cat > backend/init.sql << 'EOF'
-- Chat sessions table
CREATE TABLE IF NOT EXISTS chat_sessions (
  id UUID PRIMARY KEY,
  user_message TEXT NOT NULL,
  ai_response TEXT,
  model_used VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Stock prices table (example data)
CREATE TABLE IF NOT EXISTS stock_prices (
  id SERIAL PRIMARY KEY,
  symbol VARCHAR(10) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  change_amount DECIMAL(10,2),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO stock_prices (symbol, price, change_amount) VALUES
('AAPL', 150.25, 2.30),
('GOOGL', 2500.50, -15.75),
('MSFT', 300.10, 5.20),
('TSLA', 250.80, -3.45);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_chat_sessions_created_at ON chat_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_stock_prices_symbol ON stock_prices(symbol);
CREATE INDEX IF NOT EXISTS idx_stock_prices_recorded_at ON stock_prices(recorded_at);
EOF

    print_status "Backend setup complete"
}

# Setup frontend
setup_frontend() {
    print_header "Setting up Frontend"
    
    cat > frontend/package.json << 'EOF'
{
  "name": "ai-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@testing-library/jest-dom": "^5.17.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^14.5.2",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "axios": "^1.6.0",
    "web-vitals": "^2.1.4"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
EOF

    mkdir -p frontend/src frontend/public
    
    cat > frontend/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="AI Stack Chat Interface" />
    <title>AI Stack Chat</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF

    cat > frontend/src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

    cat > frontend/src/App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

function App() {
  const [message, setMessage] = useState('');
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selectedModel, setSelectedModel] = useState('phi3');
  const [stockSymbol, setStockSymbol] = useState('AAPL');
  const [stockData, setStockData] = useState(null);

  const sendMessage = async () => {
    if (!message.trim()) return;

    const userMessage = { text: message, sender: 'user', timestamp: new Date() };
    setMessages(prev => [...prev, userMessage]);
    setLoading(true);

    try {
      const response = await axios.post(`${API_URL}/api/chat`, {
        message: message,
        model: selectedModel
      });

      const aiMessage = {
        text: response.data.response,
        sender: 'ai',
        timestamp: new Date(),
        model: selectedModel
      };

      setMessages(prev => [...prev, aiMessage]);
    } catch (error) {
      const errorMessage = {
        text: 'Sorry, I encountered an error. Please try again.',
        sender: 'ai',
        timestamp: new Date(),
        error: true
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setLoading(false);
      setMessage('');
    }
  };

  const fetchStock = async () => {
    try {
      const response = await axios.get(`${API_URL}/api/stock/${stockSymbol}`);
      setStockData(response.data);
    } catch (error) {
      console.error('Error fetching stock:', error);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>🤖 AI Stack Chat Interface</h1>
        <p>Powered by Ollama + n8n + Local Models</p>
      </header>

      <div className="container">
        <div className="chat-section">
          <div className="model-selector">
            <label>
              Model:
              <select 
                value={selectedModel} 
                onChange={(e) => setSelectedModel(e.target.value)}
              >
                <option value="phi3">Phi-3 Mini</option>
                <option value="llama2">Llama 2 7B</option>
              </select>
            </label>
          </div>

          <div className="chat-container">
            <div className="messages">
              {messages.map((msg, index) => (
                <div key={index} className={`message ${msg.sender}`}>
                  <div className="message-content">
                    <div className="message-text">{msg.text}</div>
                    <div className="message-info">
                      {msg.model && <span className="model-tag">{msg.model}</span>}
                      <span className="timestamp">
                        {msg.timestamp.toLocaleTimeString()}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
              {loading && (
                <div className="message ai loading">
                  <div className="message-content">
                    <div className="typing-indicator">
                      <span></span><span></span><span></span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className="input-container">
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Type your message here..."
                disabled={loading}
              />
              <button onClick={sendMessage} disabled={loading || !message.trim()}>
                {loading ? 'Sending...' : 'Send'}
              </button>
            </div>
          </div>
        </div>

        <div className="stock-section">
          <h3>📈 Stock Price Demo</h3>
          <div className="stock-controls">
            <input
              type="text"
              value={stockSymbol}
              onChange={(e) => setStockSymbol(e.target.value.toUpperCase())}
              placeholder="Stock symbol"
            />
            <button onClick={fetchStock}>Get Price</button>
          </div>
          
          {stockData && (
            <div className="stock-data">
              <h4>{stockData.symbol}</h4>
              <div className="price">${stockData.price}</div>
              <div className={`change ${stockData.change >= 0 ? 'positive' : 'negative'}`}>
                {stockData.change >= 0 ? '+' : ''}{stockData.change}
              </div>
              <div className="timestamp">
                Updated: {new Date(stockData.timestamp).toLocaleString()}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
EOF

    cat > frontend/src/index.css << 'EOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f5f5f5;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF

    cat > frontend/src/App.css << 'EOF'
.App {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.App-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  text-align: center;
  padding: 2rem;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.App-header h1 {
  margin-bottom: 0.5rem;
  font-size: 2.5rem;
}

.App-header p {
  opacity: 0.9;
  font-size: 1.1rem;
}

.container {
  display: flex;
  flex: 1;
  padding: 2rem;
  gap: 2rem;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
}

.chat-section {
  flex: 2;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.1);
  overflow: hidden;
}

.model-selector {
  padding: 1rem;
  background: #f8f9fa;
  border-bottom: 1px solid #e9ecef;
}

.model-selector label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  color: #495057;
}

.model-selector select {
  padding: 0.5rem;
  border: 1px solid #ced4da;
  border-radius: 6px;
  background: white;
}

.chat-container {
  display: flex;
  flex-direction: column;
  height: 600px;
}

.messages {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.message {
  display: flex;
  max-width: 80%;
}

.message.user {
  align-self: flex-end;
}

.message.ai {
  align-self: flex-start;
}

.message-content {
  background: #e9ecef;
  padding: 1rem;
  border-radius: 12px;
  position: relative;
}

.message.user .message-content {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.message.ai .message-content {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
}

.message-text {
  margin-bottom: 0.5rem;
  line-height: 1.5;
}

.message-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
  opacity: 0.8;
  margin-top: 0.5rem;
}

.model-tag {
  background: rgba(0,0,0,0.1);
  padding: 0.2rem 0.5rem;
  border-radius: 10px;
  font-size: 0.7rem;
}

.message.user .model-tag {
  background: rgba(255,255,255,0.2);
}

.input-container {
  display: flex;
  padding: 1rem;
  border-top: 1px solid #e9ecef;
  background: #f8f9fa;
}

.input-container textarea {
  flex: 1;
  padding: 1rem;
  border: 1px solid #ced4da;
  border-radius: 8px;
  resize: none;
  height: 60px;
  font-family: inherit;
}

.input-container button {
  margin-left: 1rem;
  padding: 1rem 2rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: opacity 0.2s;
}

.input-container button:hover:not(:disabled) {
  opacity: 0.9;
}

.input-container button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.stock-section {
  flex: 1;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.1);
  padding: 1.5rem;
  height: fit-content;
}

.stock-section h3 {
  margin-bottom: 1rem;
  color: #495057;
}

.stock-controls {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.stock-controls input {
  flex: 1;
  padding: 0.5rem;
  border: 1px solid #ced4da;
  border-radius: 6px;
}

.stock-controls button {
  padding: 0.5rem 1rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

.stock-data {
  text-align: center;
  padding: 1rem;
  border: 2px solid #e9ecef;
  border-radius: 8px;
  background: #f8f9fa;
}

.stock-data h4 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #495057;
}

.stock-data .price {
  font-size: 2rem;
  font-weight: bold;
  color: #495057;
  margin-bottom: 0.5rem;
}

.stock-data .change {
  font-size: 1.2rem;
  font-weight: bold;
  margin-bottom: 0.5rem;
}

.stock-data .change.positive {
  color: #28a745;
}

.stock-data .change.negative {
  color: #dc3545;
}

.stock-data .timestamp {
  font-size: 0.8rem;
  color: #6c757d;
}

.typing-indicator {
  display: flex;
  gap: 0.3rem;
  align-items: center;
}

.typing-indicator span {
  width: 8px;
  height: 8px;
  background: #6c757d;
  border-radius: 50%;
  animation: typing 1.4s infinite ease-in-out;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing {
  0%, 80%, 100% {
    transform: scale(0.8);
    opacity: 0.5;
  }
  40% {
    transform: scale(1);
    opacity: 1;
  }
}

@media (max-width: 768px) {
  .container {
    flex-direction: column;
    padding: 1rem;
  }
  
  .chat-container {
    height: 400px;
  }
  
  .message {
    max-width: 90%;
  }
}
EOF

    cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine as build

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

    cat > frontend/nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

    print_status "Frontend setup complete"
}

# Setup n8n workflow
setup_n8n() {
    print_header "Setting up n8n Workflows"
    
    cat > n8n/workflows/chat-workflow.json << 'EOF'
{
  "name": "AI Chat Workflow",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "chat",
        "responseMode": "responseNode",
        "options": {}
      },
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [240, 300],
      "webhookId": "chat-webhook"
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://ollama:11434/api/generate",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ]
        },
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "model",
              "value": "={{ $json.body.model || 'phi3' }}"
            },
            {
              "name": "prompt",
              "value": "={{ $json.body.message }}"
            },
            {
              "name": "stream",
              "value": false
            }
          ]
        },
        "options": {}
      },
      "name": "Ollama API",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 3,
      "position": [460, 300]
    },
    {
      "parameters": {
        "respondWith": "json",
        "responseBody": "={{ { \"response\": $json.response, \"model\": $json.model, \"chatId\": $('Webhook').item.json.body.chatId } }}"
      },
      "name": "Response",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1,
      "position": [680, 300]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [
        [
          {
            "node": "Ollama API",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Ollama API": {
      "main": [
        [
          {
            "node": "Response",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": true,
  "settings": {},
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z",
  "id": 1
}
EOF

    print_status "n8n workflow created"
}

# Setup Ollama models script
setup_ollama_script() {
    print_header "Creating Ollama Model Setup Script"
    
    cat > scripts/setup-ollama.sh << 'EOF'
#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🦙 Setting up Ollama models...${NC}"

# Wait for Ollama to be ready
echo -e "${YELLOW}⏳ Waiting for Ollama service to be ready...${NC}"
RETRIES=0
MAX_RETRIES=60

while ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
    if [ $RETRIES -ge $MAX_RETRIES ]; then
        echo -e "${RED}❌ Ollama service failed to start after $MAX_RETRIES attempts${NC}"
        exit 1
    fi
    echo "   Attempt $((RETRIES + 1))/$MAX_RETRIES - waiting for Ollama..."
    sleep 5
    RETRIES=$((RETRIES + 1))
done

echo -e "${GREEN}✅ Ollama service is ready!${NC}"

# Function to pull model with progress
pull_model_with_progress() {
    local model=$1
    local model_name=$2
    
    echo -e "\n${BLUE}📥 Pulling $model_name model ($model)...${NC}"
    echo "This may take several minutes depending on your internet connection."
    echo "Model sizes: Phi-3 Mini (~2.3GB), Llama 2 7B (~3.8GB)"
    echo

    if docker exec -it ollama ollama pull "$model"; then
        echo -e "${GREEN}✅ $model_name model downloaded successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to download $model_name model${NC}"
        return 1
    fi
}

# Function to check if model exists
model_exists() {
    docker exec ollama ollama list | grep -q "$1" 2>/dev/null
}

# Pull Phi-3 Mini
if model_exists "phi3:mini"; then
    echo -e "${YELLOW}📦 Phi-3 Mini already exists, skipping download${NC}"
else
    pull_model_with_progress "phi3:mini" "Phi-3 Mini"
fi

# Pull Llama 2 7B
echo
read -p "Do you want to download Llama 2 7B? (larger model, ~3.8GB) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if model_exists "llama2:7b"; then
        echo -e "${YELLOW}📦 Llama 2 7B already exists, skipping download${NC}"
    else
        pull_model_with_progress "llama2:7b" "Llama 2 7B"
    fi
else
    echo -e "${YELLOW}⏭️  Skipping Llama 2 7B download${NC}"
fi

echo
echo -e "${GREEN}🎉 Model setup complete!${NC}"
echo -e "\n${BLUE}📋 Available models:${NC}"
docker exec ollama ollama list

echo
echo -e "${GREEN}✨ Ready to chat! Visit http://localhost:3000${NC}"
EOF

    chmod +x scripts/setup-ollama.sh
    print_status "Improved Ollama setup script created with progress indicators"
}

# Create environment file
create_env() {
    print_header "Creating Environment Configuration"
    
    cat > .env << 'EOF'
# N8N Configuration
N8N_BASIC_AUTH_ACTIVE=false
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678

# Database Configuration
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=n8n_password

# Backend Database
DATABASE_URL=postgresql://backend_user:backend_password@postgres_backend:5432/ai_app
POSTGRES_BACKEND_DB=ai_app
POSTGRES_BACKEND_USER=backend_user
POSTGRES_BACKEND_PASSWORD=backend_password

# API Configuration
REACT_APP_API_URL=http://localhost:3001
N8N_WEBHOOK_URL=http://n8n:5678/webhook

# Ollama Configuration
OLLAMA_HOST=0.0.0.0:11434
EOF

    print_status "Environment file created"
}

# Create README
create_readme() {
    print_header "Creating Documentation"
    
    cat > README_GENERATED.md << 'EOF'
# AI Stack Template - Generated

This README was auto-generated by install.sh.

## Generated Structure

The following directories have been created:
- backend/ - Node.js Express API
- frontend/ - React chat application
- n8n/workflows/ - Pre-configured chat workflow
- scripts/ - Utility scripts

## Next Steps

1. Start services: docker-compose up -d
2. Setup models: ./scripts/setup-ollama.sh
3. Access frontend: http://localhost:3000
EOF

    print_status "Documentation created"
}

# Main installation function
main() {
    print_header "AI Stack Installation"
    
    check_docker
    check_docker_compose
    create_structure
    setup_backend
    setup_frontend
    setup_n8n
    setup_ollama_script
    create_env
    create_readme
    
    print_header "Installation Complete!"
    
    echo -e "\n${GREEN}🎉 AI Stack template has been set up successfully!${NC}\n"
    
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Start the stack: ${YELLOW}docker-compose up -d${NC}"
    echo -e "2. Wait 2-3 minutes for services to initialize"
    echo -e "3. Setup AI models: ${YELLOW}./scripts/setup-ollama.sh${NC}"
    echo -e "4. Access the applications:"
    echo -e "   • Frontend: ${YELLOW}http://localhost:3000${NC}"
    echo -e "   • n8n: ${YELLOW}http://localhost:5678${NC}"
    echo -e "   • Backend API: ${YELLOW}http://localhost:3001${NC}"
    
    echo -e "\n${BLUE}Useful commands:${NC}"
    echo -e "• View logs: ${YELLOW}docker-compose logs -f${NC}"
    echo -e "• Stop services: ${YELLOW}docker-compose down${NC}"
    echo -e "• Reset everything: ${YELLOW}docker-compose down -v${NC}"
    
    echo -e "\n${GREEN}Happy coding! 🚀${NC}"
}

# Run main function
main "$@"
