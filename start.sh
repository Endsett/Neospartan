#!/bin/bash
# Railway start script for NeoSpartan Backend

set -e

echo "🚀 Starting NeoSpartan API Server..."

# Navigate to backend directory
cd backend

# Start the FastAPI server with Railway's PORT
exec python3 -m uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}" --workers 1
