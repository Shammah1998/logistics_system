# Deployment Guide - Vercel + Render

This guide covers deploying the Logistics Platform to production using:
- **Vercel** - Frontend hosting (Customer Panel & Admin Panel)
- **Render** - Backend API hosting

## Prerequisites

- GitHub account with this repository
- Vercel account (free tier works)
- Render account (free tier works)
- Supabase project set up

---

## 1. Deploy Backend to Render

### Step 1: Create Render Web Service

1. Go to [render.com](https://render.com) and sign in
2. Click **New +** → **Web Service**
3. Connect your GitHub repository
4. Configure the service:
   - **Name**: `logistics-api` (or your choice)
   - **Region**: Choose closest to your users
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`

### Step 2: Set Environment Variables

In Render dashboard, add these environment variables:

| Variable | Value |
|----------|-------|
| `NODE_ENV` | `production` |
| `SUPABASE_URL` | `https://your-project.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Your Supabase service role key |
| `CUSTOMER_PANEL_URL` | `https://your-customer-panel.vercel.app` (add after Vercel deploy) |
| `ADMIN_PANEL_URL` | `https://your-admin-panel.vercel.app` (add after Vercel deploy) |
| `LOG_LEVEL` | `info` |

### Step 3: Deploy

Click **Create Web Service**. Render will build and deploy automatically.

Note your backend URL: `https://logistics-api.onrender.com`

---

## 2. Deploy Customer Panel to Vercel

### Step 1: Import Project

1. Go to [vercel.com](https://vercel.com) and sign in
2. Click **Add New** → **Project**
3. Import your GitHub repository
4. Configure:
   - **Root Directory**: `frontend/customer-panel`
   - **Framework Preset**: Vite
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`

### Step 2: Set Environment Variables

| Variable | Value |
|----------|-------|
| `VITE_SUPABASE_URL` | `https://your-project.supabase.co` |
| `VITE_SUPABASE_ANON_KEY` | Your Supabase anonymous key |
| `VITE_API_URL` | `https://logistics-api.onrender.com/api` |

### Step 3: Deploy

Click **Deploy**. Note your URL for the next step.

---

## 3. Deploy Admin Panel to Vercel

Repeat the same steps as Customer Panel with:
- **Root Directory**: `frontend/admin-panel`

Set the same environment variables.

---

## 4. Update CORS Origins

After both Vercel deployments, go back to Render and update:

| Variable | Value |
|----------|-------|
| `CUSTOMER_PANEL_URL` | `https://your-customer-panel.vercel.app` |
| `ADMIN_PANEL_URL` | `https://your-admin-panel.vercel.app` |

Render will automatically redeploy.

---

## 5. Build Flutter App for Production

### Android APK

```bash
cd logistics_app
flutter build apk --release --dart-define=API_BASE_URL=https://logistics-api.onrender.com/api
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://logistics-api.onrender.com/api
```

### iOS (requires macOS)

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://logistics-api.onrender.com/api
```

---

## Environment Variables Summary

### Backend (Render)

```env
NODE_ENV=production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
CUSTOMER_PANEL_URL=https://your-customer-panel.vercel.app
ADMIN_PANEL_URL=https://your-admin-panel.vercel.app
LOG_LEVEL=info
```

### Frontend (Vercel) - Both Panels

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_URL=https://logistics-api.onrender.com/api
```

### Flutter App

Build with `--dart-define`:
```
API_BASE_URL=https://logistics-api.onrender.com/api
```

---

## Verification Checklist

After deployment, verify:

- [ ] Backend health check: `https://logistics-api.onrender.com/health`
- [ ] Customer Panel loads and can login
- [ ] Admin Panel loads and can login
- [ ] Admin can create drivers
- [ ] Flutter app can login with production APK

---

## Troubleshooting

### CORS Errors
- Ensure `CUSTOMER_PANEL_URL` and `ADMIN_PANEL_URL` are set correctly in Render
- Vercel preview URLs (`*.vercel.app`) are automatically allowed

### Flutter App Can't Connect
- Verify `API_BASE_URL` was set during build
- Check app is using HTTPS (not HTTP) for production URL
- Ensure backend is running (check Render logs)

### Backend Errors
- Check Render logs for detailed error messages
- Verify all environment variables are set
- Ensure Supabase URL and keys are correct

---

## Cost Estimates (Free Tiers)

| Service | Free Tier Limits |
|---------|-----------------|
| Vercel | 100GB bandwidth/month, unlimited sites |
| Render | 750 hours/month, sleeps after 15min inactivity |
| Supabase | 500MB database, 2GB bandwidth |

For production, consider upgrading Render to prevent cold starts (the free tier sleeps after 15 minutes of inactivity).


