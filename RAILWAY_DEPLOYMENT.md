# Railway Deployment Guide

Quick guide to deploy NeoSpartan backend on Railway.

## Prerequisites

- Railway account: https://railway.app
- GitHub account with repo access
- Supabase project
- Gemini API key

## Deployment Steps

### 1. Configure Environment Variables

Before deploying, set these in Railway Dashboard:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key
SUPABASE_JWT_SECRET=your-jwt-secret
GEMINI_API_KEY=your-gemini-api-key
SECRET_KEY=your-random-secret-key
ENVIRONMENT=production
```

### 2. Deploy via Railway Dashboard

**Option A: GitHub Integration**
1. Go to https://railway.app
2. Click "New Project" → "Deploy from GitHub repo"
3. Select `Endsett/Neospartan`
4. Railway will auto-detect configuration
5. Add environment variables in "Variables" tab
6. Deploy

**Option B: Railway CLI**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link project
railway link

# Deploy
railway up
```

### 3. Build Configuration

Railway will use one of these (in order of priority):

1. **`railway.json`** - Primary configuration
2. **`nixpacks.toml`** - Nixpacks builder config
3. **`Procfile`** - Heroku-style
4. **`start.sh`** - Shell script fallback

### 4. Health Check

After deployment, verify:

```bash
curl https://your-app.railway.app/health
```

Expected response:
```json
{"status": "operational", "version": "2.0.0"}
```

### 5. Test AI Endpoint

```bash
curl -X POST https://your-app.railway.app/ai/workout/generate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fitness_level": "intermediate",
    "training_goal": "strength",
    "preferred_duration": 45
  }'
```

## Troubleshooting

### "Build failed" error
- Check that `backend/requirements.txt` exists
- Verify Python version in `runtime.txt` (3.11.8)

### "Start command not found"
- Ensure `start.sh` is executable: `chmod +x start.sh`
- Check `.gitattributes` has LF line endings

### "Module not found" errors
- Verify all Python files are in `backend/` directory
- Check `requirements.txt` has all dependencies

### Database connection fails
- Verify `SUPABASE_URL` uses `https://` not `http://`
- Ensure using **service_role** key (not anon key)
- Check Supabase project is active

## Files for Railway Deployment

```
Neospartan/
├── railway.json          # Railway build config ⭐
├── nixpacks.toml         # Alternative builder config
├── Procfile              # Heroku-style process
├── start.sh              # Startup script ⭐
├── runtime.txt           # Python version
├── .gitattributes        # Line ending rules
└── backend/
    ├── main.py           # FastAPI app
    ├── requirements.txt  # Dependencies ⭐
    └── ...
```

⭐ = Critical files

## Custom Domain (Optional)

1. In Railway Dashboard, go to your service
2. Click "Settings" → "Domains"
3. Click "Generate Domain" or add custom domain
4. Update `CORS_ORIGINS` environment variable with new domain

## Monitoring

- Railway Dashboard shows logs and metrics
- Health check endpoint: `/health`
- Detailed health: `/health/detailed`

## Support

- Railway Docs: https://docs.railway.app
- Troubleshooting: Check deployment logs in Railway Dashboard
