# TrustPrism Deployment Guide

This guide will help you deploy TrustPrism to any host environment.

## Key Changes for Host Independence

Your application has been updated to work on ANY host. Here are the key improvements:

### 1. Environment-Based Configuration
- CORS origins now read from `CORS_ORIGINS` environment variable
- Frontend API URL is environment-configurable
- All hardcoded IPs and localhost addresses have been removed

### 2. Docker Configuration
- Updated `docker-compose.yml` with proper health checks
- Added support for environment variables for ports
- Database host properly configured for container networking

### 3. Application Files Updated
- **backend/index.js**: Dynamic CORS and CSP configuration
- **frontend/vite.config.js**: Intelligent API URL handling
- **docker-compose.yml**: Production-ready setup with health checks
- **Dockerfiles**: Updated for production builds

## Deployment Instructions

### Option 1: Docker Deployment (Recommended)

#### Local Testing
```bash
# Copy environment templates
cp .env.example .env
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Edit the .env files with your specific values
# Then start with Docker
docker-compose up -d
```

#### Production Deployment

**Step 1: Prepare environment files**

Create `.env` file in project root:
```bash
POSTGRES_USER=trustuser
POSTGRES_PASSWORD=change-me-strong-password
POSTGRES_DB=trustprism
DB_PORT=5432
BACKEND_PORT=5000
FRONTEND_PORT=5173
NODE_ENV=production
VITE_API_URL=    # Leave empty for same-domain, or set to https://api.yourdomain.com
```

Create `backend/.env`:
```bash
DB_HOST=postgres
DB_NAME=trustprism
DB_USER=trustuser
DB_PASS=change-me-strong-password
DB_PORT=5432
JWT_SECRET=generate-a-secure-64-character-random-string
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-specific-password
FRONTEND_URL=https://yourdomain.com    # Important for email links
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
GEMINI_API_KEY=your-key-here
```

Create `frontend/.env`:
```bash
VITE_API_URL=    # Leave empty to use same domain, or https://api.yourdomain.com:5000
```

**Step 2: Deploy with Docker**

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Option 2: Manual Server Deployment

#### Prerequisites
- Node.js 20+
- PostgreSQL 15+
- npm or yarn

#### Installation Steps

**1. Backend Setup**
```bash
cd backend
npm install
# Edit .env with your configuration
npm run start
```

**2. Frontend Setup**
```bash
cd frontend
npm install
# Edit .env with your API URL (or leave empty for same-domain)
npm run build
npm run preview    # or use a web server like nginx
```

#### Environment Variables Required

**Backend (.env)**
- `DB_HOST`: PostgreSQL host
- `DB_NAME`: Database name
- `DB_USER`: Database user
- `DB_PASS`: Database password
- `DB_PORT`: Database port (default: 5432)
- `JWT_SECRET`: Secret for JWT tokens (min 64 characters)
- `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USER`, `EMAIL_PASS`: Email configuration
- `FRONTEND_URL`: URL where frontend will be accessed (for email links)
- `CORS_ORIGINS`: Comma-separated allowed origins (or leave empty for defaults)

**Frontend (.env)**
- `VITE_API_URL`: Backend API URL (leave empty to use same domain as frontend)

### Option 3: Nginx Reverse Proxy Setup

Example nginx configuration for serving both frontend and backend:

```nginx
upstream backend {
    server backend:5000;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Frontend (static files)
    location / {
        root /var/www/trustprism/frontend/dist;
        try_files $uri /index.html;
        add_header Cache-Control "public, max-age=3600";
    }

    # Backend API
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend other routes
    location ~ ^/(auth|groups|sessions|projects|dashboard|admin|participant|friends|notifications|insights)/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support
    location /socket.io/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Important Configuration for Different Hosts

### Local Development
- Leave `CORS_ORIGINS` empty in backend/.env
- Leave `VITE_API_URL` empty in frontend/.env
- Use `docker-compose up -d`

### Single Domain Deployment (e.g., api.yourdomain.com)
- Both frontend and backend on same domain
- `CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com`
- `VITE_API_URL=` (empty, will use same domain)
- `FRONTEND_URL=https://yourdomain.com`

### Separate Backend Domain (e.g., frontend.yourdomain.com, backend-api.yourdomain.com)
- `CORS_ORIGINS=https://frontend.yourdomain.com`
- `VITE_API_URL=https://backend-api.yourdomain.com:5000`
- `FRONTEND_URL=https://frontend.yourdomain.com`

### Port Configuration
If you need custom ports, set in root `.env`:
```bash
DB_PORT=5432
BACKEND_PORT=5000
FRONTEND_PORT=5173
```

## Health Checks

Once deployed, verify the application is working:

```bash
# Check backend health
curl http://localhost:5000/health

# Check frontend is serving
curl http://localhost:5173

# Check database connection
docker-compose exec backend curl http://localhost:5000/health
```

## Troubleshooting

### CORS Errors
- Verify `CORS_ORIGINS` matches your actual frontend URL
- Include protocol (http:// or https://)
- Test with: `curl -H "Origin: your-origin" -X OPTIONS backend-url`

### API Connection Failed
- Verify `VITE_API_URL` is correct in frontend/.env
- For same-domain, leave it empty
- Check backend is accessible from frontend's network

### Database Connection Issues
- Verify `DB_HOST`, `DB_USER`, `DB_PASS` in backend/.env
- For Docker, `DB_HOST` should be `postgres` (service name)
- For manual setup, `DB_HOST` should be actual database server address

### Email Links Not Working
- Verify `FRONTEND_URL` matches your actual frontend address
- Include protocol and domain (e.g., https://yourdomain.com)

## Security Recommendations

1. Change all default secrets and passwords in production
2. Use HTTPS/SSL in production
3. Set `NODE_ENV=production` in docker-compose or production servers
4. Use strong JWT_SECRET (generate: `openssl rand -hex 32`)
5. Restrict `CORS_ORIGINS` to your actual domains
6. Use environment-specific SSL certificates
7. Keep backend `.env` file secure and not in version control

## Scaling for Production

For larger deployments:

1. Use managed database services (AWS RDS, Azure Database)
2. Scale backend horizontally behind a load balancer
3. Use CDN for static frontend files
4. Implement caching (Redis) for sessions
5. Monitor with proper logging and alerting
6. Use container orchestration (Kubernetes, Docker Swarm)

## Next Steps

1. Deploy database backups strategy
2. Set up monitoring and alerting
3. Configure automated SSL certificate renewal
4. Implement CI/CD pipeline for deployments
5. Set up disaster recovery procedures
