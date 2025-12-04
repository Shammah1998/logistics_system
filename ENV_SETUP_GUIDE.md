# Environment Variables Setup Guide

This guide explains the simplified environment configuration after the refactor.

## New Project Structure

```
logistics_system/
├── .env                      ← Main credentials (server uses this)
├── .env.example              ← Template for new setups
├── server/                   ← Node.js API (renamed from backend)
│   └── (reads from root .env)
├── client/                   ← React Apps (renamed from frontend)
│   ├── admin-panel/
│   │   └── .env              ← VITE_ prefixed variables
│   └── customer-panel/
│       └── .env              ← VITE_ prefixed variables
└── logistics_app/            ← Flutter Mobile App
    └── .env                  ← API_BASE_URL only
```

## Quick Setup

### 1. Root `.env` (Main Configuration)
This is the primary configuration file for the server:

```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Server
PORT=3000
NODE_ENV=development

# API
API_BASE_URL=http://localhost:3000/api

# Frontend URLs (for CORS)
ADMIN_PANEL_URL=http://localhost:3002
CUSTOMER_PANEL_URL=http://localhost:3001

# Redis Cache (Optional - server works without it but slower)
# Local: redis://localhost:6379
# Production: Use your Redis provider URL (Upstash, Redis Cloud, etc.)
REDIS_URL=redis://localhost:6379
```

### 2. Client Apps `.env` (Vite Requirement)
Vite requires `VITE_` prefix. Each client app has a small `.env`:

```env
# client/admin-panel/.env and client/customer-panel/.env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
# Production only:
# VITE_API_URL=https://your-backend.onrender.com/api
```

### 3. Flutter App `.env`
```env
API_BASE_URL=http://localhost:3000/api
```

---

## Running Locally

### Server (API)
```bash
cd server
npm install
npm run dev
```
Server runs on: http://localhost:3000

### Admin Panel
```bash
cd client/admin-panel
npm install
npm run dev
```
Admin panel runs on: http://localhost:3002

### Customer Panel
```bash
cd client/customer-panel
npm install
npm run dev
```
Customer panel runs on: http://localhost:3001

### Flutter App
```bash
cd logistics_app
flutter run
```

---

## Production Deployment

### Server → Render
1. Set **Root Directory** to `server`
2. Add environment variables in Render dashboard:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `NODE_ENV=production`
   - `ADMIN_PANEL_URL=https://your-admin.vercel.app`
   - `CUSTOMER_PANEL_URL=https://your-customer.vercel.app`
   - `REDIS_URL` (recommended: use Upstash Redis free tier for caching)

### Admin Panel → Vercel
1. Set **Root Directory** to `client/admin-panel`
2. Add environment variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `VITE_API_URL=https://your-backend.onrender.com/api`

### Customer Panel → Vercel
1. Set **Root Directory** to `client/customer-panel`
2. Add environment variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `VITE_API_URL=https://your-backend.onrender.com/api`

### Flutter App → APK
```bash
cd logistics_app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-backend.onrender.com/api
```

---

## Switching Between Local and Production

### For Local Development
All `.env` files are already configured for localhost. Just run the apps.

### For Production Testing
1. **Server**: Deploy to Render or run locally
2. **Client apps**: Uncomment and set `VITE_API_URL` in their `.env` files
3. **Flutter**: Change `API_BASE_URL` in `logistics_app/.env`

---

## Redis Caching

The server uses Redis for intelligent caching to make the API fast and reduce database load.

### Cache Strategy
| Endpoint | TTL | Reason |
|----------|-----|--------|
| Dashboard stats | 30s | Frequently requested, aggregates multiple queries |
| Orders list | 15s | Changes often, needs to be current |
| Drivers list | 60s | Changes less frequently |
| Customers list | 120s | Rarely changes |
| User profile | 300s | Static data |

### Cache Invalidation
- Cache is automatically invalidated when data changes (create/update/delete)
- Admin can manually clear cache via `/api/admin/cache/clear`

### Local Development
- Redis is **optional** - server runs without it
- If you want local caching: `docker run -p 6379:6379 redis`

### Production (Recommended: Upstash)
1. Sign up at https://upstash.com (free tier available)
2. Create a Redis database
3. Copy the connection URL
4. Add `REDIS_URL` to your Render environment variables

---

## Security Notes

- ✅ All `.env` files are in `.gitignore`
- ✅ `SUPABASE_SERVICE_ROLE_KEY` is only used by server (never in client/mobile)
- ✅ Production secrets should be set in hosting dashboards, not committed
