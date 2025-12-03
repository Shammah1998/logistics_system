# Environment Variables Setup Guide

This guide explains how to configure environment variables for all components of the logistics system.

## 📋 Table of Contents

- [Overview](#overview)
- [Backend Setup](#backend-setup)
- [Admin Panel Setup](#admin-panel-setup)
- [Customer Panel Setup](#customer-panel-setup)
- [Flutter App Setup](#flutter-app-setup)
- [Getting Supabase Credentials](#getting-supabase-credentials)

## Overview

All components require Supabase credentials to function. **Hardcoded credentials have been removed** for security. You must configure environment variables before running any component.

## Backend Setup

### 1. Create `.env` file

Create a `.env` file in the `backend/` directory:

```bash
cd backend
cp .env.example .env  # If .env.example exists, or create manually
```

### 2. Add Required Variables

Create `backend/.env` with the following content:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Server Configuration
PORT=3000
NODE_ENV=development

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:5173
```

### 3. Replace Placeholder Values

Replace the placeholder values with your actual Supabase credentials (see [Getting Supabase Credentials](#getting-supabase-credentials)).

### 4. Run the Backend

```bash
npm install
npm run dev
```

**Note:** The server will exit with an error if required environment variables are missing.

---

## Admin Panel Setup

### 1. Create `.env` file

Create a `.env` file in the `frontend/admin-panel/` directory:

```bash
cd frontend/admin-panel
```

### 2. Add Required Variables

Create `frontend/admin-panel/.env` with the following content:

```env
# Supabase Configuration
# Note: Vite requires the VITE_ prefix for environment variables
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Replace Placeholder Values

Replace the placeholder values with your actual Supabase credentials.

### 4. Run the Admin Panel

```bash
npm install
npm run dev
```

**Note:** The app will display an error screen if environment variables are missing.

---

## Customer Panel Setup

### 1. Create `.env` file

Create a `.env` file in the `frontend/customer-panel/` directory:

```bash
cd frontend/customer-panel
```

### 2. Add Required Variables

Create `frontend/customer-panel/.env` with the following content:

```env
# Supabase Configuration
# Note: Vite requires the VITE_ prefix for environment variables
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Replace Placeholder Values

Replace the placeholder values with your actual Supabase credentials.

### 4. Run the Customer Panel

```bash
npm install
npm run dev
```

**Note:** The app will display an error screen if environment variables are missing.

---

## Flutter App Setup

**Important:** The Flutter app does NOT connect directly to Supabase. It communicates with the backend API, which handles all database operations. This is the industry-standard secure architecture.

The Flutter app automatically loads environment variables from a `.env` file, just like `npm run dev` does for the backend.

### 1. Create `.env` file

The `.env` file is already created for you in `logistics_app/.env`. If it doesn't exist, the run scripts will create it automatically.

The `.env` file should contain:
```env
# Backend API URL
API_BASE_URL=http://localhost:3000/api
```

### 2. Run the App

**Using the run script (Recommended - automatically loads .env):**
```bash
cd logistics_app
run.bat        # Windows
# or
./run.sh       # Linux/Mac (chmod +x run.sh first time)
```

The scripts automatically:
- Check for `.env` file (create with defaults if missing)
- Read `API_BASE_URL` from `.env`
- Pass it to `flutter run` via `--dart-define` flags

**Just like `npm run dev` in the backend!** 🎉

### 3. Manual Run (Alternative)

If you prefer to run manually without the script:

```bash
cd logistics_app
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

### 3. For Production Builds

**Android:**
```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://your-api-domain.com/api
```

**iOS:**
```bash
flutter build ios \
  --dart-define=API_BASE_URL=https://your-api-domain.com/api
```

### Architecture Note

The Flutter app uses a secure architecture:
- **Flutter App** → **Backend API** → **Supabase Database**
- The app only needs the `API_BASE_URL` environment variable
- All authentication and database operations go through the backend API
- Supabase credentials are only stored in the backend (never in the mobile app)

---

## Getting Supabase Credentials

### Step 1: Access Supabase Dashboard

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Sign in to your account
3. Select your project (or create a new one)

### Step 2: Get API Credentials

1. Navigate to **Settings** → **API** (or go to `https://app.supabase.com/project/YOUR_PROJECT_ID/settings/api`)
2. You'll find:
   - **Project URL** → Use this for `SUPABASE_URL`
   - **anon/public key** → Use this for `SUPABASE_ANON_KEY` (frontend apps)
   - **service_role key** → Use this for `SUPABASE_SERVICE_ROLE_KEY` (backend only)

### Step 3: Get Database Connection String (Optional)

If you need direct PostgreSQL access:

1. Navigate to **Settings** → **Database**
2. Find the **Connection string** section
3. Copy the connection string (use the **URI** format)
4. Use this for `POSTGRES_CONNECTION_STRING` (if needed)

### ⚠️ Security Notes

- **Never commit `.env` files** to version control (they're in `.gitignore`)
- **Never share** your `SUPABASE_SERVICE_ROLE_KEY` publicly
- The **anon key** is safe for frontend use (it's public)
- The **service_role key** should **only** be used in backend/server code

---

## Quick Start Checklist

- [ ] Create `backend/.env` with Supabase credentials
- [ ] Create `frontend/admin-panel/.env` with Supabase credentials
- [ ] Create `frontend/customer-panel/.env` with Supabase credentials
- [ ] Test backend: `cd backend && npm run dev` (must be running before Flutter app)
- [ ] Test admin panel: `cd frontend/admin-panel && npm run dev`
- [ ] Test customer panel: `cd frontend/customer-panel && npm run dev`
- [ ] Test Flutter app: `cd logistics_app && run.bat` (or `./run.sh` on Linux/Mac)
  - **Note:** Flutter app only needs `API_BASE_URL` - no Supabase credentials needed

---

## Troubleshooting

### Backend: "Missing required environment variables"

- Check that `backend/.env` exists
- Verify all required variables are set (no empty values)
- Restart the server after creating/updating `.env`

### Frontend: Error screen on load

- Check that `.env` file exists in the correct directory
- Verify variables start with `VITE_` prefix
- Restart the dev server after creating/updating `.env`
- Clear browser cache if needed

### Flutter: Error screen on launch

- Verify `--dart-define=API_BASE_URL=...` flag is provided
- Ensure the backend API is running and accessible
- Check that the API_BASE_URL points to the correct backend server
- Rebuild the app after adding environment variables
- **Note:** Flutter app only needs `API_BASE_URL` - no Supabase credentials needed

### Environment Variables Not Loading

**Backend (Node.js):**
- Ensure `dotenv` package is installed
- Check that `.env` file is in the `backend/` directory
- Restart the server

**Frontend (Vite):**
- Variables must start with `VITE_` prefix
- Restart the dev server after changes
- Check browser console for errors

**Flutter:**
- Environment variables must be provided at compile time
- Use `--dart-define` flags every time you run/build
- Rebuild the app after changing variables

---

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Vite Environment Variables](https://vitejs.dev/guide/env-and-mode.html)
- [Flutter Environment Variables](https://docs.flutter.dev/deployment/environment-variables)

