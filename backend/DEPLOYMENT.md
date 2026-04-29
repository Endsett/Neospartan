# NeoSpartan Backend Deployment Guide

This guide covers deploying the NeoSpartan backend to production.

## Prerequisites

- Docker and Docker Compose installed
- Supabase project set up
- Redis instance (local or cloud)
- Domain name and SSL certificate (for production)
- Environment variables configured

## Environment Variables

Create a `.env` file based on `.env.example`:

```env
# Required
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key
SUPABASE_JWT_SECRET=your-jwt-secret
GEMINI_API_KEY=your-gemini-api-key
SECRET_KEY=your-app-secret-key

# Optional (with defaults)
GEMINI_MODEL=gemini-1.5-flash
REDIS_URL=redis://localhost:6379/0
ENVIRONMENT=production
ENABLE_METRICS=true
SENTRY_DSN=your-sentry-dsn (optional)
```

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/your-org/neospartan.git
cd neospartan/backend
cp .env.example .env
# Edit .env with your values
```

### 2. Run with Docker Compose

```bash
docker-compose up -d
```

This starts:
- API server on port 8000
- Redis on port 6379
- Background worker

### 3. Verify Deployment

```bash
curl http://localhost:8000/health
curl http://localhost:8000/health/detailed
```

## Production Deployment

### Option 1: Self-Hosted with Docker

1. **Server Requirements:**
   - 2+ CPU cores
   - 4GB+ RAM
   - 20GB+ storage
   - Ubuntu 20.04+ or similar

2. **Install Docker:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

3. **Deploy:**
   ```bash
   docker-compose -f docker-compose.yml up -d
   ```

### Option 2: Cloud Deployment

#### Railway/Render
1. Connect GitHub repository
2. Set environment variables in dashboard
3. Deploy automatically on push

#### AWS/GCP/Azure
1. Build Docker image: `docker build -t neospartan-api .`
2. Push to registry
3. Deploy to container service
4. Configure load balancer and SSL

### Option 3: Kubernetes

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

## Database Migrations

Run migrations manually:

```bash
docker-compose exec api python -c "from migrations import migration_manager; import asyncio; asyncio.run(migration_manager.migrate_up())"
```

Or check migration status:

```bash
docker-compose exec api python -c "from migrations import migration_manager; import asyncio; print(asyncio.run(migration_manager.get_status()))"
```

## Monitoring

### Health Checks
- Basic: `GET /health`
- Detailed: `GET /health/detailed`
- Database: Included in detailed check

### Metrics
Prometheus metrics available at `/metrics` when `ENABLE_METRICS=true`

### Sentry
Set `SENTRY_DSN` for error tracking

### Logs
View logs:
```bash
docker-compose logs -f api
docker-compose logs -f worker
```

## SSL/HTTPS

### With Nginx (Recommended)

```nginx
server {
    listen 443 ssl http2;
    server_name api.neospartan.ai;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### With Traefik (Docker Compose)

```yaml
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.email=admin@neospartan.ai"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./letsencrypt:/letsencrypt

  api:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.neospartan.ai`)"
      - "traefik.http.routers.api.tls.certresolver=letsencrypt"
      - "traefik.http.services.api.loadbalancer.server.port=8000"
```

## Scaling

### Horizontal Scaling

1. **Load Balancer:** Nginx/HAProxy/Traefik
2. **Multiple API instances:**
   ```yaml
   services:
     api:
       deploy:
         replicas: 3
   ```
3. **Shared Redis:** Central Redis instance
4. **Database:** Supabase handles scaling

### Vertical Scaling

Increase resources:
```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

## Backup & Recovery

### Redis Data
```bash
docker-compose exec redis redis-cli save
docker cp neospartan-redis:/data/dump.rdb ./backup/
```

### Database
Use Supabase backup features or pg_dump:
```bash
pg_dump $DATABASE_URL > backup.sql
```

## Troubleshooting

### Common Issues

1. **Database connection errors:**
   - Check SUPABASE_URL and SUPABASE_KEY
   - Verify IP whitelist in Supabase

2. **Redis connection errors:**
   - Ensure REDIS_URL is correct
   - Check if Redis container is running

3. **High memory usage:**
   - Reduce uvicorn workers
   - Enable response caching
   - Monitor for memory leaks

4. **Slow response times:**
   - Enable caching
   - Check database query performance
   - Scale horizontally

### Debug Mode

```bash
docker-compose exec api python -c "import main; print(main.app.state)"
```

## Security Checklist

- [ ] Change default SECRET_KEY
- [ ] Enable HTTPS
- [ ] Configure CORS origins
- [ ] Set up rate limiting
- [ ] Enable Sentry monitoring
- [ ] Regular security updates
- [ ] Database backups
- [ ] Log retention policy

## Support

For deployment issues:
1. Check logs: `docker-compose logs`
2. Review health endpoints
3. Verify environment variables
4. Check Supabase dashboard
5. Contact: support@neospartan.ai
