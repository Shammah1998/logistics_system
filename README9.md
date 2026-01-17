# Logistics Platform - Installation & Setup

## Installation & Setup

This section provides step-by-step, zero-assumption instructions for setting up the entire Logistics Platform from scratch. Every command, every step, and every configuration is explained in detail.

---

## Prerequisites

Before you begin, ensure you have the following installed on your system:

### Required Software

**1. Node.js and npm**
- **Version Required:** Node.js 18.0.0 or higher
- **How to Check:** Open terminal/command prompt and run:
  ```bash
  node --version
  npm --version
  ```
- **If Not Installed:**
  - **Windows/Mac:** Download from https://nodejs.org/
  - **Linux:** Use package manager:
    ```bash
    # Ubuntu/Debian
    sudo apt update
    sudo apt install nodejs npm
    
    # Or use Node Version Manager (nvm)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    nvm install 18
    ```

**2. Git**
- **Version Required:** Any recent version
- **How to Check:**
  ```bash
  git --version
  ```
- **If Not Installed:**
  - **Windows/Mac:** Download from https://git-scm.com/
  - **Linux:** `sudo apt install git` (Ubuntu/Debian)

**3. Flutter SDK** (For Mobile App Development)
- **Version Required:** Flutter 3.10.0 or higher
- **How to Check:**
  ```bash
  flutter --version
  ```
- **If Not Installed:**
  - Follow official guide: https://docs.flutter.dev/get-started/install
  - **Windows:** Download Flutter SDK, extract, add to PATH
  - **Mac/Linux:** Use Flutter installer or download SDK manually

**4. Supabase Account**
- **Required:** Free Supabase account
- **How to Get:** Sign up at https://supabase.com
- **What You'll Need:**
  - Project URL (e.g., `https://xxxxx.supabase.co`)
  - Anon Key (public key, safe to expose)
  - Service Role Key (secret key, backend only)

**5. Code Editor** (Recommended)
- **VS Code:** https://code.visualstudio.com/
- **Or any editor:** VS Code, WebStorm, Sublime Text, etc.

### Optional Software

**6. Redis** (Optional - for caching)
- **Why Optional:** Server works without Redis, but slower
- **How to Install:**
  - **Windows:** Download from https://redis.io/download or use Docker
  - **Mac:** `brew install redis`
  - **Linux:** `sudo apt install redis-server`
  - **Or Use Docker:** `docker run -p 6379:6379 redis`

**7. PostgreSQL Client** (Optional - for database inspection)
- **pgAdmin:** https://www.pgadmin.org/
- **Or use Supabase Dashboard:** Built-in SQL editor

**8. Postman or Insomnia** (Optional - for API testing)
- **Postman:** https://www.postman.com/
- **Insomnia:** https://insomnia.rest/

---

## Step 1: Clone or Download the Project

### Option A: If You Have Git

```bash
# Clone the repository
git clone <repository-url>
cd logistics_system
```

### Option B: If You Don't Have Git

1. Download the project as a ZIP file
2. Extract it to a folder (e.g., `C:\CascadeProjects\logistics_system`)
3. Open terminal/command prompt in that folder

### Verify Project Structure

You should see these folders:
```
logistics_system/
├── server/
├── client/
│   ├── admin-panel/
│   └── customer-panel/
├── logistics_app/
└── [various files]
```

---

## Step 2: Set Up Supabase Database

### 2.1 Create Supabase Project

1. **Go to:** https://supabase.com
2. **Sign up** or **Log in**
3. **Click:** "New Project"
4. **Fill in:**
   - **Name:** `logistics-platform` (or any name)
   - **Database Password:** Choose a strong password (save it!)
   - **Region:** Choose closest to you
5. **Click:** "Create new project"
6. **Wait:** 2-3 minutes for project to initialize

### 2.2 Get Your Supabase Credentials

1. **In Supabase Dashboard:**
   - Click **Settings** (gear icon) → **API**
2. **Copy These Values:**
   - **Project URL:** `https://xxxxx.supabase.co`
   - **anon/public key:** Long string starting with `eyJ...`
   - **service_role key:** Long string starting with `eyJ...` (click "Reveal" to see it)

**⚠️ Important:**
- **anon key:** Safe to expose (used in frontend)
- **service_role key:** NEVER expose (backend only, has full access)

### 2.3 Initialize Database Schema

1. **In Supabase Dashboard:**
   - Click **SQL Editor** (left sidebar)
   - Click **New Query**

2. **Run Schema File:**
   - Open `server/database/schema.sql` in your code editor
   - Copy **ALL** contents
   - Paste into Supabase SQL Editor
   - Click **Run** (or press Ctrl+Enter)
   - **Wait:** Should complete in 10-30 seconds
   - **Verify:** You should see "Success. No rows returned"

3. **Run RLS Policies:**
   - Open `server/database/rls_policies.sql` in your code editor
   - Copy **ALL** contents
   - Paste into Supabase SQL Editor
   - Click **Run**
   - **Verify:** Should see "Success. No rows returned"

4. **Verify Tables Created:**
   - Click **Table Editor** (left sidebar)
   - You should see 14 tables:
     - `users`, `companies`, `drivers`, `vehicles`, `orders`, `order_items`, `drops`, `pods`, `wallets`, `transactions`, `withdrawal_requests`, `price_cards`, `audit_logs`, `notifications`

### 2.4 Create Admin User (Optional - Can Do Later)

**Method 1: Using Script (Recommended)**
- We'll do this after setting up the server (Step 4)

**Method 2: Manual SQL**
- Run `server/database/create_admin_user.sql` in Supabase SQL Editor
- Or use the script: `npm run create-admin` (after server setup)

---

## Step 3: Configure Environment Variables

### 3.1 Root `.env` File (Server Configuration)

1. **Navigate to project root:**
   ```bash
   cd logistics_system
   ```

2. **Create `.env` file:**
   - **Windows:** Create new file named `.env` (no extension)
   - **Mac/Linux:** `touch .env`

3. **Open `.env` in your code editor** and paste:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Server Configuration
PORT=3000
NODE_ENV=development

# API Configuration
API_BASE_URL=http://localhost:3000/api

# Frontend URLs (for CORS)
ADMIN_PANEL_URL=http://localhost:3002
CUSTOMER_PANEL_URL=http://localhost:3001

# Redis Cache (Optional - leave empty if not using Redis)
# Local Redis: redis://localhost:6379
# Production: Use your Redis provider URL
REDIS_URL=redis://localhost:6379
```

4. **Replace Placeholder Values:**
   - Replace `https://your-project-id.supabase.co` with your actual Supabase URL
   - Replace `your-anon-key-here` with your actual anon key
   - Replace `your-service-role-key-here` with your actual service role key
   - **Keep other values as-is** for local development

5. **Save the file**

**⚠️ Important:**
- Never commit `.env` to git (it's in `.gitignore`)
- Keep service role key secret (never share it)

### 3.2 Admin Panel `.env` File

1. **Navigate to admin panel:**
   ```bash
   cd client/admin-panel
   ```

2. **Create `.env` file:**
   - **Windows:** Create new file named `.env`
   - **Mac/Linux:** `touch .env`

3. **Open `.env` and paste:**

```env
# Supabase Configuration (Vite requires VITE_ prefix)
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here

# API URL (leave empty for local development - uses Vite proxy)
# For production: VITE_API_URL=https://your-backend.onrender.com/api
```

4. **Replace Placeholder Values:**
   - Use the same Supabase URL and anon key from root `.env`
   - Leave `VITE_API_URL` empty for local development

5. **Save the file**

### 3.3 Customer Panel `.env` File

1. **Navigate to customer panel:**
   ```bash
   cd client/customer-panel
   ```

2. **Create `.env` file:**
   - Same process as admin panel

3. **Open `.env` and paste:**

```env
# Supabase Configuration (Vite requires VITE_ prefix)
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here

# API URL (leave empty for local development - uses Vite proxy)
# For production: VITE_API_URL=https://your-backend.onrender.com/api
```

4. **Replace Placeholder Values:**
   - Use the same Supabase URL and anon key
   - Leave `VITE_API_URL` empty for local development

5. **Save the file**

### 3.4 Flutter App Configuration

**Option A: Using `.env` File (Simple)**

1. **Navigate to Flutter app:**
   ```bash
   cd logistics_app
   ```

2. **Create `.env` file:**
   - Create new file named `.env`

3. **Open `.env` and paste:**

```env
API_BASE_URL=http://localhost:3000/api
```

4. **Save the file**

**Option B: Using Build-Time Constants (Production)**

- We'll cover this in the production deployment section
- For local development, `.env` file is simpler

---

## Step 4: Install Dependencies

### 4.1 Install Server Dependencies

1. **Navigate to server directory:**
   ```bash
   cd server
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```
   - **Wait:** 1-3 minutes (downloads all packages)
   - **What It Does:** Reads `package.json` and installs all dependencies

3. **Verify Installation:**
   ```bash
   npm list --depth=0
   ```
   - Should show list of installed packages (no errors)

### 4.2 Install Admin Panel Dependencies

1. **Navigate to admin panel:**
   ```bash
   cd client/admin-panel
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```
   - **Wait:** 1-3 minutes

3. **Verify Installation:**
   ```bash
   npm list --depth=0
   ```

### 4.3 Install Customer Panel Dependencies

1. **Navigate to customer panel:**
   ```bash
   cd client/customer-panel
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```
   - **Wait:** 1-3 minutes

3. **Verify Installation:**
   ```bash
   npm list --depth=0
   ```

### 4.4 Install Flutter Dependencies

1. **Navigate to Flutter app:**
   ```bash
   cd logistics_app
   ```

2. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```
   - **Wait:** 2-5 minutes (first time is slower)
   - **What It Does:** Downloads all packages listed in `pubspec.yaml`

3. **Verify Installation:**
   ```bash
   flutter doctor
   ```
   - Should show all checks passing (or warnings you can ignore)

---

## Step 5: Start Redis (Optional)

**If you want caching enabled:**

### Windows

**Option 1: Using Docker (Recommended)**
```bash
docker run -d -p 6379:6379 redis
```

**Option 2: Download Redis for Windows**
- Download from: https://github.com/microsoftarchive/redis/releases
- Extract and run `redis-server.exe`

### Mac

```bash
# Install Redis
brew install redis

# Start Redis
brew services start redis
```

### Linux

```bash
# Install Redis
sudo apt install redis-server

# Start Redis
sudo systemctl start redis-server

# Enable auto-start on boot
sudo systemctl enable redis-server
```

### Verify Redis is Running

```bash
# Test connection
redis-cli ping
# Should return: PONG
```

**If Redis is not running:**
- Server will still work (just slower, no caching)
- You'll see warning: "Running without cache"

---

## Step 6: Start the Server

1. **Navigate to server directory:**
   ```bash
   cd server
   ```

2. **Start the server:**
   ```bash
   npm run dev
   ```
   - **What It Does:** Starts Express server with nodemon (auto-restart on changes)

3. **Verify Server is Running:**
   - You should see:
     ```
     🚀 Server running on port 3000
     env: development
     port: 3000
     cache: Redis connected (or Running without cache)
     ```
   - **If you see errors:** Check the error message (common issues below)

4. **Test Server:**
   - Open browser: http://localhost:3000
   - Should see JSON response: `{"success": true, "message": "Logistics Platform API", ...}`
   - Test health check: http://localhost:3000/health
   - Should see: `{"status": "ok", "timestamp": "...", "cache": "connected"}`

5. **Keep this terminal open** (server must stay running)

**Common Issues:**

**Error: "Missing required environment variables"**
- **Solution:** Check your root `.env` file exists and has all required variables

**Error: "Cannot connect to Supabase"**
- **Solution:** Verify `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are correct

**Error: "Port 3000 already in use"**
- **Solution:** Change `PORT=3001` in `.env` (or stop the other service using port 3000)

---

## Step 7: Create Admin User

**Now that the server is running, create your first admin user:**

### Method 1: Using Script (Recommended)

1. **Open a NEW terminal window** (keep server running in first terminal)

2. **Navigate to server:**
   ```bash
   cd server
   ```

3. **Run create-admin script:**
   ```bash
   npm run create-admin
   ```

4. **Follow prompts:**
   - Enter email: `admin@example.com` (or your email)
   - Enter password: Choose a strong password
   - Enter name: `Admin User` (or your name)

5. **Verify:**
   - Should see: "Admin user created successfully!"
   - User ID and email displayed

### Method 2: Manual SQL (Alternative)

1. **In Supabase Dashboard:**
   - Go to **SQL Editor**
   - Open `server/database/create_admin_user.sql`
   - Copy contents
   - Replace `'admin@example.com'` with your email
   - Replace `'your-password'` with your password
   - Run the query

2. **Verify:**
   - Go to **Table Editor** → `users` table
   - Should see your admin user with `user_type = 'admin'`

**⚠️ Important:**
- Save your admin credentials (email and password)
- You'll need them to log into the admin panel

---

## Step 8: Start Admin Panel

1. **Open a NEW terminal window** (keep server running)

2. **Navigate to admin panel:**
   ```bash
   cd client/admin-panel
   ```

3. **Start development server:**
   ```bash
   npm run dev
   ```

4. **Verify:**
   - Should see: `Local: http://localhost:3002`
   - Vite dev server starts

5. **Open in browser:**
   - Go to: http://localhost:3002
   - Should see login page

6. **Log in:**
   - Use the admin email and password you created
   - Should redirect to dashboard

7. **Keep this terminal open** (admin panel must stay running)

**Common Issues:**

**Error: "Cannot connect to API"**
- **Solution:** Make sure server is running on port 3000
- **Check:** Vite proxy configuration in `vite.config.js`

**Error: "Supabase connection failed"**
- **Solution:** Check `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `.env`

---

## Step 9: Start Customer Panel

1. **Open a NEW terminal window** (keep server and admin panel running)

2. **Navigate to customer panel:**
   ```bash
   cd client/customer-panel
   ```

3. **Start development server:**
   ```bash
   npm run dev
   ```

4. **Verify:**
   - Should see: `Local: http://localhost:3001`
   - Vite dev server starts

5. **Open in browser:**
   - Go to: http://localhost:3001
   - Should see login/signup page

6. **Create test customer account:**
   - Click "Sign Up"
   - Enter email, password, name
   - Verify email (check Supabase dashboard or email if configured)
   - Log in

7. **Keep this terminal open** (customer panel must stay running)

**Common Issues:**

**Same as admin panel** (check API connection and Supabase config)

---

## Step 10: Set Up Flutter Mobile App

### 10.1 Configure API URL

**If using `.env` file:**
- Already configured in Step 3.4
- Make sure `API_BASE_URL=http://localhost:3000/api`

**If using build-time constants:**
- We'll cover this in production section

### 10.2 Run on Emulator/Device

**Option A: Android Emulator**

1. **Start Android Emulator:**
   - Open Android Studio
   - Tools → Device Manager
   - Start an emulator

2. **Run Flutter app:**
   ```bash
   cd logistics_app
   flutter run
   ```
   - **Wait:** 2-5 minutes (first build is slow)
   - App should launch on emulator

**Option B: Physical Device**

1. **Enable Developer Mode:**
   - Android: Settings → About Phone → Tap "Build Number" 7 times
   - Enable "USB Debugging"

2. **Connect device:**
   - Connect via USB
   - Accept USB debugging prompt on device

3. **Verify device:**
   ```bash
   flutter devices
   ```
   - Should see your device listed

4. **Run app:**
   ```bash
   flutter run
   ```

**Option C: iOS Simulator (Mac Only)**

1. **Start iOS Simulator:**
   - Open Xcode
   - Xcode → Open Developer Tool → Simulator

2. **Run app:**
   ```bash
   flutter run
   ```

### 10.3 Test Driver Login

1. **Create a driver in admin panel:**
   - Log into admin panel
   - Go to Drivers page
   - Click "Add Driver"
   - Fill in: Name, Phone, PIN (remember the PIN!)
   - Save

2. **Log in from mobile app:**
   - Open app on device/emulator
   - Enter phone number (format: `0712345678` or `+254712345678`)
   - Enter PIN
   - Should log in successfully

**Common Issues:**

**Error: "Connection refused"**
- **Solution:** Make sure server is running on port 3000
- **Note:** If using physical device, use your computer's IP address instead of `localhost`
  - Find IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
  - Update `.env`: `API_BASE_URL=http://192.168.1.100:3000/api` (use your IP)

**Error: "Flutter not found"**
- **Solution:** Make sure Flutter is installed and in PATH
- Verify: `flutter --version`

---

## Step 11: Verify Everything Works

### 11.1 Server Health Check

1. **Open browser:** http://localhost:3000/health
2. **Should see:**
   ```json
   {
     "status": "ok",
     "timestamp": "2024-01-01T12:00:00.000Z",
     "cache": "connected" or "disconnected"
   }
   ```

### 11.2 Admin Panel

1. **Log in:** http://localhost:3002
2. **Verify:**
   - Dashboard loads with statistics
   - Can view orders list
   - Can view drivers list
   - Can view customers list

### 11.3 Customer Panel

1. **Log in:** http://localhost:3001
2. **Verify:**
   - Can view orders list
   - Can place new order (form loads)
   - Can track orders

### 11.4 Mobile App

1. **Log in with driver credentials**
2. **Verify:**
   - Home page loads
   - Orders list loads
   - Earnings page loads
   - Profile page loads

### 11.5 API Endpoints

**Test with browser or Postman:**

1. **Get all orders (admin):**
   - URL: http://localhost:3000/api/orders
   - Method: GET
   - Headers: `Authorization: Bearer <admin-token>`
   - Should return orders list

2. **Get driver profile:**
   - URL: http://localhost:3000/api/drivers/profile
   - Method: GET
   - Headers: `Authorization: Bearer <driver-token>`
   - Should return driver data

**How to Get Token:**
- Log into admin panel → Open browser DevTools → Application → Local Storage → Copy token
- Or use Postman to log in and get token from response

---

## Step 12: Set Up Test Data (Optional)

### 12.1 Create Test Customers

1. **Via Customer Panel:**
   - Sign up with different email addresses
   - Each signup creates a customer account

### 12.2 Create Test Drivers

1. **Via Admin Panel:**
   - Go to Drivers page
   - Click "Add Driver"
   - Fill in details:
     - Name: `John Driver`
     - Phone: `0712345678`
     - PIN: `1234` (or any PIN)
     - Vehicle Type: `small`
     - License Number: `DL12345`
   - Save

### 12.3 Create Test Orders

1. **Via Customer Panel:**
   - Log in as customer
   - Go to "Place Order"
   - Fill in:
     - Pickup address
     - Delivery address
     - Vehicle type
     - Notes (optional)
   - Click "Place Order"
   - Order should appear in orders list

### 12.4 Assign Orders to Drivers

1. **Via Admin Panel:**
   - Go to Orders page
   - Click on an order
   - Click "Assign Driver"
   - Select a driver
   - Save
   - Order status should change to "assigned"

---

## Troubleshooting Common Issues

### Issue: "Cannot connect to Supabase"

**Symptoms:**
- Server fails to start
- Error: "Invalid API key" or "Connection refused"

**Solutions:**
1. **Check `.env` file:**
   - Verify `SUPABASE_URL` is correct (no trailing slash)
   - Verify `SUPABASE_SERVICE_ROLE_KEY` is correct (full key, not truncated)

2. **Check Supabase Dashboard:**
   - Go to Settings → API
   - Verify project is active (not paused)
   - Regenerate keys if needed

3. **Check Internet Connection:**
   - Supabase requires internet connection
   - Test: `ping supabase.co`

### Issue: "Port already in use"

**Symptoms:**
- Error: "EADDRINUSE: address already in use"

**Solutions:**
1. **Find process using port:**
   ```bash
   # Windows
   netstat -ano | findstr :3000
   
   # Mac/Linux
   lsof -i :3000
   ```

2. **Kill process:**
   ```bash
   # Windows (replace PID with actual process ID)
   taskkill /PID <PID> /F
   
   # Mac/Linux
   kill -9 <PID>
   ```

3. **Or change port:**
   - Update `PORT=3001` in `.env` (server)
   - Update `VITE_API_URL` in client `.env` files if needed

### Issue: "Module not found"

**Symptoms:**
- Error: "Cannot find module 'express'" or similar

**Solutions:**
1. **Reinstall dependencies:**
   ```bash
   cd server  # or client/admin-panel, etc.
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **Check Node version:**
   ```bash
   node --version
   ```
   - Should be 18.0.0 or higher
   - If not, upgrade Node.js

### Issue: "Flutter build fails"

**Symptoms:**
- Error during `flutter run` or `flutter build`

**Solutions:**
1. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check Flutter doctor:**
   ```bash
   flutter doctor
   ```
   - Fix any issues shown

3. **Check Android/iOS setup:**
   - Android: Android Studio, SDK installed
   - iOS: Xcode installed (Mac only)

### Issue: "CORS errors in browser"

**Symptoms:**
- Browser console shows: "CORS policy blocked"

**Solutions:**
1. **Check server CORS configuration:**
   - Verify `ADMIN_PANEL_URL` and `CUSTOMER_PANEL_URL` in root `.env`
   - Should match actual frontend URLs

2. **Check frontend URLs:**
   - Admin panel: http://localhost:3002
   - Customer panel: http://localhost:3001
   - Server allows localhost in development

### Issue: "Database tables not found"

**Symptoms:**
- Error: "relation 'orders' does not exist"

**Solutions:**
1. **Re-run schema:**
   - Go to Supabase SQL Editor
   - Run `server/database/schema.sql` again
   - Verify tables exist in Table Editor

2. **Check RLS policies:**
   - Run `server/database/rls_policies.sql` again
   - Verify policies exist in Supabase Dashboard → Authentication → Policies

### Issue: "Cannot log in as admin"

**Symptoms:**
- Login fails even with correct credentials

**Solutions:**
1. **Verify admin user exists:**
   ```bash
   cd server
   npm run check-admin
   ```
   - Should show admin user details

2. **Check user_type:**
   - Go to Supabase Table Editor → `users` table
   - Verify `user_type = 'admin'` for your user

3. **Recreate admin user:**
   ```bash
   npm run create-admin
   ```

### Issue: "Redis connection failed"

**Symptoms:**
- Warning: "Running without cache"
- Server still works but slower

**Solutions:**
1. **Check Redis is running:**
   ```bash
   redis-cli ping
   ```
   - Should return: `PONG`

2. **Start Redis:**
   - See Step 5 above

3. **Or ignore:**
   - Server works without Redis (just slower)
   - Optional for development

---

## Quick Start Summary

**For experienced developers, here's the TL;DR:**

```bash
# 1. Set up Supabase project and run schema.sql + rls_policies.sql

# 2. Configure .env files (root, admin-panel, customer-panel, logistics_app)

# 3. Install dependencies
cd server && npm install
cd ../client/admin-panel && npm install
cd ../customer-panel && npm install
cd ../../logistics_app && flutter pub get

# 4. Start services (in separate terminals)
cd server && npm run dev                    # Terminal 1
cd client/admin-panel && npm run dev        # Terminal 2
cd client/customer-panel && npm run dev     # Terminal 3
cd logistics_app && flutter run             # Terminal 4

# 5. Create admin user
cd server && npm run create-admin

# 6. Access:
# - Server: http://localhost:3000
# - Admin Panel: http://localhost:3002
# - Customer Panel: http://localhost:3001
# - Mobile App: Running on device/emulator
```

---

## Next Steps

After successful setup:

1. **Read the Documentation:**
   - README1.md - Overview
   - README2.md - Server Components
   - README3.md - Frontend Applications
   - README4.md - Mobile App
   - README5.md - User Flows
   - README6.md - Database Design
   - README7.md - File Structure
   - README8.md - Security Model

2. **Explore the System:**
   - Create test orders
   - Assign orders to drivers
   - Test order tracking
   - Explore admin dashboard

3. **Customize:**
   - Update branding/colors
   - Add custom fields
   - Modify pricing logic
   - Add new features

4. **Deploy to Production:**
   - See DEPLOYMENT_INSTRUCTIONS.md (when available)
   - Set up production environment variables
   - Deploy to Render (server) and Vercel (frontend)

---

**End of README9.md**

**Next Section:** README10.md will cover API Endpoints & Routing Logic in detail.
