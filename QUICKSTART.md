# 🚀 NeoSpartan Backend - Quick Start Guide

Get the production backend running in 5 minutes.

## Prerequisites

- Python 3.11+ installed
- A Supabase project (free tier works)
- Google Gemini API key (free tier works)

---

## Step 1: Configure Environment

```bash
cd backend

# Copy environment template
cp .env.example .env

# Edit .env with your credentials
```

### Required Variables

```bash
# Supabase - Get from supabase.com dashboard
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key  # Settings → API → service_role key
SUPABASE_JWT_SECRET=your-jwt-secret  # Settings → API → JWT Secret

# Gemini - Get from makersuite.google.com
GEMINI_API_KEY=your-gemini-api-key
```

---

## Step 2: Install & Run

```bash
# Install dependencies
pip install -r requirements.txt

# Start server
uvicorn main:app --reload
```

Server starts at `http://localhost:8000`

---

## Step 3: Verify

### Test Health Endpoint
```bash
curl http://localhost:8000/health
```

Expected response:
```json
{"status": "operational", "version": "2.0.0"}
```

### Test Exercises
```bash
curl http://localhost:8000/exercises
```

### View API Docs
Open: http://localhost:8000/docs

---

## Step 4: Test AI Generation (with auth)

### Get a test token
For local testing, create a test token:

```python
from auth import create_access_token
token = create_access_token({"sub": "test-user", "email": "test@test.com"})
print(token)
```

### Test AI endpoint
```bash
curl -X POST http://localhost:8000/ai/workout/generate \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "fitness_level": "intermediate",
    "training_goal": "strength",
    "preferred_duration": 45
  }'
```

---

## Docker Quick Start

### Using Docker Compose (Recommended)

```bash
cd backend

# Start everything (API + Redis + Worker)
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop
docker-compose down
```

### Using Docker directly

```bash
cd backend

# Build
docker build -t neospartan-api .

# Run
docker run -p 8000:8000 \
  -e SUPABASE_URL=your-url \
  -e SUPABASE_KEY=your-key \
  -e GEMINI_API_KEY=your-key \
  neospartan-api
```

---

## Fly.io Deployment

```bash
cd backend

# Login (first time)
fly auth login

# Create app (first time)
fly apps create neospartan-api

# Set secrets
fly secrets set SUPABASE_URL=your-url
fly secrets set SUPABASE_KEY=your-key
fly secrets set GEMINI_API_KEY=your-key
fly secrets set SUPABASE_JWT_SECRET=your-secret
fly secrets set SECRET_KEY=your-secret

# Deploy
fly deploy
```

---

## Troubleshooting

### "Module not found" errors
```bash
pip install -r requirements.txt
```

### "Database connection failed"
- Check SUPABASE_URL and SUPABASE_KEY in .env
- Ensure using **service_role** key (not anon key)
- Verify Supabase project is active

### "Gemini API failed"
- Check GEMINI_API_KEY in .env
- Verify API key has quota at makersuite.google.com
- Check if model name is correct (gemini-1.5-flash or gemini-1.5-pro)

### Port already in use
```bash
# Use different port
uvicorn main:app --port 8001
```

---

## File Structure

```
backend/
├── main.py              ← FastAPI app (start here)
├── config.py            ← Settings
├── database.py          ← Supabase integration
├── ai_engine.py         ← Gemini AI
├── auth.py              ← Authentication
├── websocket_manager.py ← WebSocket
├── worker.py            ← Background tasks
├── requirements.txt     ← Dependencies
├── Dockerfile           ← Container build
├── docker-compose.yml   ← Local stack
├── fly.toml             ← Fly.io config
├── test_main.py         ← Tests
├── README.md            ← Full docs
└── .env                 ← Your secrets
```

---

## Need Help?

1. Check `BACKEND_DEPLOYMENT_SUMMARY.md` for full documentation
2. Check `DEPLOYMENT_COMPLETE.md` for feature details
3. Read `backend/README.md` for API reference
4. Run `pytest test_main.py -v` to verify setup

---

**You're ready to deploy!** 🎉
