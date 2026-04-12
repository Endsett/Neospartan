# NeoSpartan Backend API

Production-ready FastAPI backend for the NeoSpartan AI fitness platform.

## Features

- 🏋️ **AI Workout Generation** - Google Gemini-powered personalized workouts
- 🗄️ **Supabase Integration** - PostgreSQL database for exercises, users, and AI memories
- 🔐 **JWT Authentication** - Secure authentication with Supabase Auth
- 🌐 **WebSocket Real-Time** - Live workout progress and AI streaming
- 📊 **DOM-RL Engine** - Rule-based fallback for workout optimization
- 🐳 **Docker Ready** - Containerized deployment
- 🚀 **Production Ready** - Health checks, rate limiting, structured logging

## Quick Start

### Prerequisites

- Python 3.11+
- Redis (optional, for background tasks)
- Supabase account
- Google Gemini API key

### Installation

```bash
# Clone and navigate
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Start server
uvicorn main:app --reload
```

### Environment Variables

```bash
# Required
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key
SUPABASE_JWT_SECRET=your-jwt-secret
GEMINI_API_KEY=your-gemini-api-key

# Optional
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=your-secret-key
SENTRY_DSN=your-sentry-dsn
ENVIRONMENT=development
```

## API Documentation

### Public Endpoints

```
GET /health                    → Basic health check
GET /health/detailed           → Detailed health with service status
GET /exercises                 → Static exercise library
GET /stoic/primer              → Stoic philosophy quote
POST /dom-rl/optimize          → DOM-RL workout optimization
POST /ephor-scrutiny/analyze   → Weekly performance analysis
POST /tactical-retreat/check   → Recovery recommendation
```

### Authenticated Endpoints (JWT Required)

```
POST /ai/workout/generate      → AI-powered workout generation
GET /exercises/dynamic         → Dynamic exercise library from Supabase
POST /exercises/create         → Create custom exercise
GET /users/profile             → User profile data
POST /users/profile            → Update user profile
WS /ws/workout/{user_id}       → WebSocket for real-time updates
```

## WebSocket Usage

Connect to WebSocket for real-time features:

```javascript
const ws = new WebSocket('ws://localhost:8000/ws/workout/user-123');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'workout_started',
    data: { session_id: 'abc123' }
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received:', message);
};
```

## Docker Deployment

### Local Docker Compose

```bash
cd backend
docker-compose up -d
```

Services:
- `api` - FastAPI server (port 8000)
- `redis` - Redis cache/queue (port 6379)
- `worker` - Background task worker

### Production Build

```bash
docker build -t neospartan-api .
docker run -p 8000:8000 --env-file .env neospartan-api
```

### Fly.io Deployment

```bash
cd backend
fly deploy
```

## Testing

```bash
# Run tests
pytest test_main.py -v

# Test health endpoint
curl http://localhost:8000/health

# Test with authentication
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8000/ai/workout/generate \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"fitness_level": "intermediate"}'
```

## Architecture

```
┌─────────────────┐
│   Flutter App   │
└────────┬────────┘
         │ HTTP/WebSocket
         ▼
┌─────────────────┐
│  FastAPI Server │
│  ┌───────────┐  │
│  │   Auth    │  │ ← JWT/Supabase
│  └─────┬─────┘  │
│  ┌─────┴─────┐  │
│  │  Gemini   │  │ ← Google AI
│  │   AI      │  │
│  └─────┬─────┘  │
│  ┌─────┴─────┐  │
│  │  DOM-RL   │  │ ← Fallback
│  └─────┬─────┘  │
└────────┼────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────┐
│Supabase│ │  Redis │
│(Postgre│ │(Queue/ │
│ SQL)   │ │ Cache) │
└────────┘ └────────┘
```

## Project Structure

```
backend/
├── main.py              # FastAPI application
├── config.py            # Settings management
├── database.py          # Supabase repositories
├── ai_engine.py         # Gemini AI + DOM-RL
├── auth.py              # JWT authentication
├── websocket_manager.py # WebSocket connections
├── worker.py            # Background tasks
├── requirements.txt     # Dependencies
├── Dockerfile           # Container build
├── docker-compose.yml   # Local stack
├── fly.toml             # Fly.io config
├── test_main.py         # Test suite
└── .env.example         # Environment template
```

## License

MIT License - NeoSpartan Project
