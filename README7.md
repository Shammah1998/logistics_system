# Logistics Platform - File & Folder Structure

## File & Folder Structure

This section provides a complete, annotated tree of the entire Logistics Platform project. Each folder and important file is explained with its purpose, when it runs, and how it fits into the system architecture.

---

## Complete Project Tree

```
logistics_system/
│
├── .env                          # Root environment variables (server config)
├── .env.example                  # Template for environment setup
├── .gitignore                    # Git ignore rules
│
├── README.md                     # Quick-start guide (existing)
├── README1.md                    # Project Overview & Architecture
├── README2.md                    # Server/Backend Components
├── README3.md                    # Admin & Customer Panels
├── README4.md                    # Flutter Driver App
├── README5.md                    # User Flows & Workflows
├── README6.md                    # Database Design & Data Flow
├── README7.md                    # File & Folder Structure (this file)
│
├── server/                       # Backend API Server
│   ├── src/                      # Source code
│   │   ├── server.js             # Main entry point, Express setup
│   │   ├── controllers/          # Request handlers
│   │   │   └── orderController.js
│   │   ├── middleware/           # Express middleware
│   │   │   ├── auth.js           # Authentication & authorization
│   │   │   ├── errorHandler.js   # Global error handling
│   │   │   └── rateLimiter.js    # Rate limiting
│   │   ├── repositories/         # Data access layer
│   │   │   └── orderRepository.js
│   │   ├── routes/               # API route definitions
│   │   │   ├── authRoutes.js     # Authentication endpoints
│   │   │   ├── orderRoutes.js    # Order management endpoints
│   │   │   ├── driverRoutes.js   # Driver management endpoints
│   │   │   ├── customerRoutes.js # Customer data endpoints
│   │   │   ├── dashboardRoutes.js # Dashboard statistics
│   │   │   ├── adminRoutes.js    # Admin operations
│   │   │   └── podRoutes.js      # Proof of delivery endpoints
│   │   ├── services/             # Business logic layer
│   │   │   ├── orderService.js   # Order business logic
│   │   │   ├── pricingService.js # Price calculations
│   │   │   └── cacheService.js   # Redis caching
│   │   └── utils/                # Utility functions
│   │       ├── logger.js         # Winston logging
│   │       └── mapsService.js    # Google Maps integration
│   │
│   ├── database/                 # Database schema and migrations
│   │   ├── schema.sql            # Complete database schema
│   │   ├── rls_policies.sql       # Row Level Security policies
│   │   ├── create_admin_user.sql # Admin user creation script
│   │   ├── create_aggregation_functions.sql # Performance functions
│   │   ├── optimize_indexes.sql # Index optimization
│   │   ├── migration_*.sql       # Database migrations
│   │   └── [various fix scripts] # Database maintenance scripts
│   │
│   ├── scripts/                   # Utility scripts
│   │   ├── create-admin.js       # Create admin user script
│   │   └── check-admin-user.js   # Verify admin user script
│   │
│   ├── logs/                     # Log files (development only)
│   │   ├── combined.log          # All logs
│   │   └── error.log             # Error logs only
│   │
│   ├── package.json              # Node.js dependencies and scripts
│   ├── render.yaml               # Render.com deployment config
│   └── README.md                 # Server-specific documentation
│
├── client/                       # Frontend Web Applications
│   │
│   ├── admin-panel/               # Admin Panel (React/Vite)
│   │   ├── src/                   # Source code
│   │   │   ├── App.jsx            # Main app component, routes
│   │   │   ├── main.jsx           # React entry point
│   │   │   ├── index.css          # Global styles
│   │   │   ├── components/        # Reusable UI components
│   │   │   │   ├── AdminLayout.jsx # Main layout wrapper
│   │   │   │   ├── Sidebar.jsx    # Navigation sidebar
│   │   │   │   ├── Header.jsx     # Top header bar
│   │   │   │   ├── ProtectedRoute.jsx # Route protection
│   │   │   │   └── ErrorBoundary.jsx # Error handling
│   │   │   ├── pages/             # Page components
│   │   │   │   ├── Login.jsx      # Admin login
│   │   │   │   ├── Dashboard.jsx  # Statistics dashboard
│   │   │   │   ├── OrdersList.jsx # Orders management
│   │   │   │   ├── OrderDetail.jsx # Order details view
│   │   │   │   ├── DriversList.jsx # Driver management
│   │   │   │   └── CustomersList.jsx # Customer list
│   │   │   ├── contexts/          # React Context providers
│   │   │   │   └── AuthContext.jsx # Authentication state
│   │   │   └── config/            # Configuration
│   │   │       └── api.js         # API URL configuration
│   │   ├── package.json           # Dependencies
│   │   ├── vite.config.js         # Vite build configuration
│   │   ├── tailwind.config.js     # Tailwind CSS configuration
│   │   ├── vercel.json            # Vercel deployment config
│   │   └── README.md              # Admin panel documentation
│   │
│   └── customer-panel/            # Customer Panel (React/Vite)
│       ├── src/                   # Source code
│       │   ├── App.jsx            # Main app component, routes
│       │   ├── main.jsx           # React entry point
│       │   ├── index.css          # Global styles
│       │   ├── components/        # Reusable UI components
│       │   │   ├── Layout.jsx     # Main layout wrapper
│       │   │   ├── Header.jsx     # Top header bar
│       │   │   ├── Breadcrumbs.jsx # Breadcrumb navigation
│       │   │   ├── ProtectedRoute.jsx # Route protection
│       │   │   └── ErrorBoundary.jsx # Error handling
│       │   ├── pages/             # Page components
│       │   │   ├── Login.jsx      # Customer login
│       │   │   ├── Signup.jsx     # Customer registration
│       │   │   ├── PlaceOrder.jsx # Order creation
│       │   │   ├── OrdersList.jsx # Order history
│       │   │   └── OrderTracking.jsx # Order tracking
│       │   ├── contexts/           # React Context providers
│       │   │   └── AuthContext.jsx # Authentication state
│       │   └── config/            # Configuration
│       │       └── api.js         # API URL configuration
│       ├── package.json           # Dependencies
│       ├── vite.config.js        # Vite build configuration
│       ├── tailwind.config.js    # Tailwind CSS configuration
│       ├── vercel.json           # Vercel deployment config
│       └── README.md             # Customer panel documentation
│
├── logistics_app/                 # Flutter Driver Mobile App
│   ├── lib/                       # Dart source code
│   │   ├── main.dart              # App entry point
│   │   ├── core/                  # Core functionality
│   │   │   ├── config/
│   │   │   │   └── app_config.dart # API URLs, constants
│   │   │   ├── services/
│   │   │   │   └── api_service.dart # HTTP client, API calls
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart # Theme definitions
│   │   │   └── utils/
│   │   │       └── responsive.dart # Responsive utilities
│   │   └── presentation/          # UI layer
│   │       ├── pages/             # Screen components
│   │       │   ├── login/
│   │       │   │   └── login_page.dart
│   │       │   ├── home/
│   │       │   │   └── home_page.dart
│   │       │   ├── orders/
│   │       │   │   └── orders_page.dart
│   │       │   ├── earnings/
│   │       │   │   └── earnings_page.dart
│   │       │   └── profile/
│   │       │       └── profile_page.dart
│   │       ├── providers/
│   │       │   └── auth_provider.dart # Riverpod auth state
│   │       ├── routes/
│   │       │   └── app_router.dart # Navigation routing
│   │       └── widgets/
│   │           └── bottom_nav_bar.dart # Bottom navigation
│   │
│   ├── android/                   # Android-specific files
│   │   ├── app/                   # Android app configuration
│   │   │   ├── build.gradle.kts   # Build configuration
│   │   │   └── src/               # Android resources
│   │   ├── build.gradle.kts       # Project build config
│   │   └── [Gradle files]        # Gradle wrapper and config
│   │
│   ├── ios/                       # iOS-specific files
│   │   ├── Runner/                # iOS app configuration
│   │   │   ├── Info.plist        # iOS app info
│   │   │   └── [Xcode files]      # Xcode project files
│   │   └── [Xcode project files]  # Xcode workspace
│   │
│   ├── web/                       # Web-specific files
│   │   ├── index.html            # Web entry point
│   │   └── [web assets]          # Web icons and manifest
│   │
│   ├── pubspec.yaml               # Flutter dependencies
│   ├── pubspec.lock               # Locked dependency versions
│   ├── run.bat                    # Windows run script
│   ├── run.sh                     # Linux/Mac run script
│   ├── app.md                     # App-specific documentation
│   └── README.md                  # Flutter app documentation
│
├── reference_images/              # UI/UX reference materials
│   ├── README.md                  # Reference images guide
│   ├── admin_panel_layouts.txt   # Admin panel layout specs
│   ├── customer_panel_layouts.txt # Customer panel layout specs
│   └── mobile_app_layouts.txt    # Mobile app layout specs
│
├── testsprite_tests/              # TestSprite test files
│   └── tmp/                       # Temporary test files
│
└── [Documentation Files]          # Various markdown documentation
    ├── ENV_SETUP_GUIDE.md        # Environment setup guide
    ├── DEPLOYMENT_INSTRUCTIONS.md # Deployment guide
    ├── API_DOCUMENTATION.md       # API reference (in server/)
    └── [Various fix/audit docs]  # Historical documentation
```

---

## Root Directory Files

### `.env`

**Purpose:** Main environment configuration file for the server.

**What It Contains:**
- Supabase credentials (URL, anon key, service role key)
- Server port configuration
- Redis cache configuration
- Frontend URLs for CORS
- API base URL

**When It's Used:**
- Server startup (reads Supabase credentials)
- Runtime (all environment variables accessed via `process.env`)

**Who Uses It:**
- Server only (backend reads from root `.env`)
- Client apps have their own `.env` files

**Why Root Level:**
- Server can read from root directory
- Single source of truth for backend configuration
- Easy to manage in production deployments

### `.env.example`

**Purpose:** Template file showing required environment variables.

**What It Contains:**
- All required environment variables with placeholder values
- Comments explaining each variable
- Example values for reference

**When It's Used:**
- Initial setup (copy to `.env` and fill in values)
- Documentation reference
- Team onboarding

**Why It Exists:**
- Prevents committing sensitive `.env` to git
- Provides setup instructions
- Documents all required variables

---

## Server Directory (`server/`)

### Purpose

The server directory contains the entire backend API application. It's a Node.js/Express.js application that handles all business logic, database operations, and API endpoints.

### Key Directories

#### `server/src/`

**Purpose:** Contains all source code for the backend API.

**Structure:**
- **`server.js`**: Main entry point - initializes Express, middleware, routes
- **`controllers/`**: Request handlers - process HTTP requests, call services
- **`middleware/`**: Express middleware - auth, errors, rate limiting
- **`repositories/`**: Data access layer - database queries (partially implemented)
- **`routes/`**: API route definitions - maps URLs to controllers
- **`services/`**: Business logic - order processing, pricing, caching
- **`utils/`**: Utility functions - logging, maps integration

**When It Runs:**
- Server startup: `server.js` is executed
- Request handling: Routes → Middleware → Controllers → Services
- Background: Cache service connects to Redis on startup

#### `server/database/`

**Purpose:** Contains all database-related files (schema, migrations, policies).

**Key Files:**
- **`schema.sql`**: Complete database schema - run once to create all tables
- **`rls_policies.sql`**: Row Level Security policies - run after schema
- **`migration_*.sql`**: Database migrations - run in order to update schema
- **`create_admin_user.sql`**: Script to create first admin user
- **`optimize_indexes.sql`**: Performance optimization scripts

**When It's Used:**
- **Initial Setup**: Run `schema.sql` to create database
- **Migrations**: Run migration files when schema changes
- **Maintenance**: Run optimization scripts as needed

**Who Uses It:**
- Database administrators
- Developers setting up local environment
- CI/CD pipelines for database setup

#### `server/scripts/`

**Purpose:** Utility scripts for common administrative tasks.

**Key Files:**
- **`create-admin.js`**: Creates admin user account
  - Usage: `npm run create-admin`
  - When: Initial setup or adding new admin
- **`check-admin-user.js`**: Verifies admin user exists
  - Usage: `npm run check-admin`
  - When: Troubleshooting authentication issues

**When They Run:**
- Manually via npm scripts
- During initial setup
- When creating new admin accounts

#### `server/logs/`

**Purpose:** Stores log files (development only).

**Files:**
- **`combined.log`**: All log entries
- **`error.log`**: Error-level logs only

**When It's Used:**
- Development environment only
- Production uses external logging (Render logs)
- Helps debug issues locally

**Why Development Only:**
- Render (production host) has ephemeral filesystem
- Logs are lost on server restart
- Use external logging service in production

#### `server/package.json`

**Purpose:** Defines Node.js dependencies, scripts, and metadata.

**Key Sections:**
- **`dependencies`**: Runtime dependencies (Express, Supabase, Redis, etc.)
- **`devDependencies`**: Development tools (nodemon, eslint, prettier)
- **`scripts`**: npm commands (start, dev, create-admin, etc.)

**When It's Used:**
- `npm install`: Installs all dependencies
- `npm run dev`: Starts development server
- `npm start`: Starts production server

---

## Client Directories

### `client/admin-panel/`

**Purpose:** React web application for platform administrators.

**Key Directories:**

#### `client/admin-panel/src/`

**Structure:**
- **`App.jsx`**: Main component - defines routes and layout
- **`main.jsx`**: React entry point - renders App component
- **`components/`**: Reusable UI components (Layout, Sidebar, Header)
- **`pages/`**: Page components (Dashboard, Orders, Drivers, Customers)
- **`contexts/`**: React Context providers (AuthContext)
- **`config/`**: Configuration files (API URLs)

**When It Runs:**
- Development: `npm run dev` starts Vite dev server (port 3002)
- Production: Built and deployed to Vercel
- Browser: User navigates to admin panel URL

#### `client/admin-panel/vite.config.js`

**Purpose:** Vite build tool configuration.

**What It Configures:**
- Build settings
- Development server port (3002)
- Proxy configuration (for API calls in development)

**When It's Used:**
- Development: Vite reads this for dev server settings
- Build: Vite reads this for production build

#### `client/admin-panel/tailwind.config.js`

**Purpose:** Tailwind CSS configuration.

**What It Configures:**
- Color palette
- Spacing scale
- Breakpoints
- Custom utilities

**When It's Used:**
- Build time: Tailwind processes CSS classes
- Runtime: Styles applied to components

### `client/customer-panel/`

**Purpose:** React web application for end customers.

**Structure:** Similar to admin-panel but with customer-focused pages.

**Key Differences:**
- **Pages**: PlaceOrder, OrderTracking (instead of management pages)
- **Port**: 3001 (different from admin panel)
- **Auth**: No admin check, just customer authentication

---

## Flutter App Directory (`logistics_app/`)

### Purpose

Contains the Flutter mobile application for delivery drivers.

### Key Directories

#### `logistics_app/lib/`

**Purpose:** Contains all Dart source code.

**Structure:**
- **`main.dart`**: App entry point - initializes app and routing
- **`core/`**: Core functionality (config, services, theme, utils)
- **`presentation/`**: UI layer (pages, providers, routes, widgets)

**When It Runs:**
- Development: `flutter run` compiles and runs on device/emulator
- Production: `flutter build apk` creates Android APK
- Runtime: App starts, checks auth, shows appropriate screen

#### `logistics_app/android/`

**Purpose:** Android-specific configuration and resources.

**Key Files:**
- **`app/build.gradle.kts`**: Android app build configuration
- **`build.gradle.kts`**: Project-level build configuration
- **`local.properties`**: Local SDK paths (not committed to git)

**When It's Used:**
- Android build: Gradle reads these files
- Android Studio: IDE uses these for project setup

#### `logistics_app/ios/`

**Purpose:** iOS-specific configuration and resources.

**Key Files:**
- **`Runner/Info.plist`**: iOS app configuration
- **`Runner.xcodeproj/`**: Xcode project files
- **`Runner.xcworkspace/`**: Xcode workspace

**When It's Used:**
- iOS build: Xcode reads these files
- iOS development: Xcode uses these for project setup

#### `logistics_app/pubspec.yaml`

**Purpose:** Defines Flutter dependencies and app metadata.

**Key Sections:**
- **`dependencies`**: Runtime packages (riverpod, http, shared_preferences, etc.)
- **`dev_dependencies`**: Development tools (flutter_test, flutter_lints)
- **`flutter:`**: Flutter-specific configuration

**When It's Used:**
- `flutter pub get`: Installs all dependencies
- Build: Flutter reads this for dependencies

---

## Configuration Files

### Build Configuration Files

#### `vite.config.js` (Admin & Customer Panels)

**Purpose:** Configures Vite build tool for React apps.

**What It Configures:**
- Development server settings
- Build output settings
- Proxy configuration (API calls in dev)

**When It Runs:**
- Development: Vite dev server uses this
- Build: Vite build process uses this

#### `tailwind.config.js` (Admin & Customer Panels)

**Purpose:** Configures Tailwind CSS utility framework.

**What It Configures:**
- Color palette
- Typography scale
- Spacing scale
- Custom components

**When It Runs:**
- Build time: Tailwind processes CSS
- Development: Hot reload uses this

#### `vercel.json` (Admin & Customer Panels)

**Purpose:** Vercel deployment configuration.

**What It Configures:**
- Build settings
- Environment variables
- Routing rules

**When It's Used:**
- Vercel deployment: Vercel reads this during deployment

#### `render.yaml` (Server)

**Purpose:** Render.com deployment configuration.

**What It Configures:**
- Service type (web service)
- Build command
- Start command
- Environment variables

**When It's Used:**
- Render deployment: Render reads this during deployment

---

## Environment Files

### Root `.env`

**Location:** `logistics_system/.env`

**Used By:** Server only

**Contains:**
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_ANON_KEY`: Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY`: Supabase service role key (backend only)
- `PORT`: Server port (default: 3000)
- `REDIS_URL`: Redis connection URL (optional)
- `ADMIN_PANEL_URL`: Admin panel URL (for CORS)
- `CUSTOMER_PANEL_URL`: Customer panel URL (for CORS)

**Security:** Never committed to git (in `.gitignore`)

### Client `.env` Files

**Location:** `client/admin-panel/.env` and `client/customer-panel/.env`

**Used By:** Respective React applications

**Contains:**
- `VITE_SUPABASE_URL`: Supabase project URL
- `VITE_SUPABASE_ANON_KEY`: Supabase anonymous key
- `VITE_API_URL`: Backend API URL (production only)

**Note:** Vite requires `VITE_` prefix for environment variables to be exposed to frontend code.

**Security:** Never committed to git (in `.gitignore`)

### Flutter `.env` File

**Location:** `logistics_app/.env` (optional)

**Used By:** Flutter app (via build-time constants)

**Contains:**
- `API_BASE_URL`: Backend API URL

**Note:** Flutter uses `--dart-define` for build-time constants instead of `.env` files.

---

## Documentation Files

### Root Documentation

**`README.md`**: Quick-start guide with basic setup instructions

**`README1.md` through `README15.md`**: Comprehensive system documentation (this series)

**`ENV_SETUP_GUIDE.md`**: Detailed environment variable setup guide

**`DEPLOYMENT_INSTRUCTIONS.md`**: Production deployment guide

### Server Documentation

**`server/README.md`**: Server-specific documentation

**`server/API_DOCUMENTATION.md`**: Complete API endpoint reference

**`server/PRICING_ENGINE.md`**: Pricing calculation documentation

### Flutter App Documentation

**`logistics_app/README.md`**: Flutter app setup guide

**`logistics_app/app.md`**: Detailed app documentation (security, features, etc.)

---

## Reference Materials

### `reference_images/`

**Purpose:** Contains UI/UX design specifications and layout references.

**Files:**
- **`README.md`**: Guide to reference materials
- **`admin_panel_layouts.txt`**: Admin panel layout specifications
- **`customer_panel_layouts.txt`**: Customer panel layout specifications
- **`mobile_app_layouts.txt`**: Mobile app layout specifications

**When It's Used:**
- UI/UX development
- Design reference
- Layout planning

**Who Uses It:**
- Frontend developers
- UI/UX designers
- Product managers

---

## How Files Interact

### Server Startup Sequence

```
1. Node.js executes server/src/server.js
   │
   ├─ Reads .env file (root directory)
   │
   ├─ Validates required environment variables
   │
   ├─ Initializes Supabase client
   │
   ├─ Initializes Express app
   │
   ├─ Configures middleware (CORS, helmet, compression, rate limiting)
   │
   ├─ Registers routes (from server/src/routes/)
   │
   ├─ Sets up error handler
   │
   ├─ Connects to Redis (optional, non-blocking)
   │
   └─ Starts listening on PORT (default: 3000)
```

### React App Startup Sequence

```
1. Browser loads index.html
   │
   ├─ Vite dev server serves React app
   │
   ├─ main.jsx executes
   │
   ├─ React renders App.jsx
   │
   ├─ App.jsx sets up routes
   │
   ├─ AuthContext initializes
   │   │
   │   ├─ Checks for Supabase session
   │   │
   │   └─ Fetches user_type from database
   │
   ├─ ProtectedRoute checks authentication
   │
   └─ Renders appropriate page component
```

### Flutter App Startup Sequence

```
1. Flutter executes lib/main.dart
   │
   ├─ WidgetsFlutterBinding.ensureInitialized()
   │
   ├─ Creates ProviderScope (Riverpod)
   │
   ├─ Renders LogisticsApp widget
   │
   ├─ Watches authProvider state
   │
   ├─ authProvider._init() executes
   │   │
   │   ├─ Retrieves token from SharedPreferences
   │   │
   │   ├─ Calls ApiService.verifyToken()
   │   │
   │   └─ Updates auth state
   │
   ├─ Based on auth state:
   │   │
   │   ├─ If authenticated: Shows HomePage
   │   │
   │   └─ If not authenticated: Shows LoginPage
   │
   └─ App ready for user interaction
```

---

## File Naming Conventions

### Server Files

**Naming Pattern:** `camelCase.js`

**Examples:**
- `server.js` - Main entry point
- `orderController.js` - Controller files
- `authRoutes.js` - Route files
- `pricingService.js` - Service files

**Why:**
- JavaScript convention
- Consistent with Node.js ecosystem

### React Files

**Naming Pattern:** `PascalCase.jsx` for components, `camelCase.js` for utilities

**Examples:**
- `App.jsx` - Main app component
- `Dashboard.jsx` - Page component
- `AuthContext.jsx` - Context provider
- `api.js` - Utility file

**Why:**
- React convention (components are PascalCase)
- Matches component naming in JSX

### Flutter Files

**Naming Pattern:** `snake_case.dart`

**Examples:**
- `main.dart` - Entry point
- `api_service.dart` - Service files
- `auth_provider.dart` - Provider files
- `login_page.dart` - Page files

**Why:**
- Dart/Flutter convention
- Consistent with Flutter ecosystem

---

## Directory Purpose Summary

| Directory | Purpose | Who Uses It | When It Runs |
|-----------|---------|-------------|--------------|
| `server/` | Backend API | Backend developers, DevOps | Server startup, API requests |
| `client/admin-panel/` | Admin web app | Admin users, frontend developers | Browser access, development |
| `client/customer-panel/` | Customer web app | Customers, frontend developers | Browser access, development |
| `logistics_app/` | Driver mobile app | Drivers, mobile developers | App launch, development |
| `server/database/` | Database schema | DBAs, backend developers | Initial setup, migrations |
| `server/scripts/` | Utility scripts | Admins, developers | Manual execution |
| `reference_images/` | Design specs | Designers, developers | Design/development phase |

---

## Important Files by Function

### Authentication

**Server:**
- `server/src/middleware/auth.js` - Authentication middleware
- `server/src/routes/authRoutes.js` - Auth endpoints

**Admin Panel:**
- `client/admin-panel/src/contexts/AuthContext.jsx` - Auth state
- `client/admin-panel/src/pages/Login.jsx` - Login page

**Customer Panel:**
- `client/customer-panel/src/contexts/AuthContext.jsx` - Auth state
- `client/customer-panel/src/pages/Login.jsx` - Login page
- `client/customer-panel/src/pages/Signup.jsx` - Registration page

**Flutter App:**
- `logistics_app/lib/presentation/providers/auth_provider.dart` - Auth state
- `logistics_app/lib/presentation/pages/login/login_page.dart` - Login page

### Order Management

**Server:**
- `server/src/routes/orderRoutes.js` - Order endpoints
- `server/src/controllers/orderController.js` - Order request handling
- `server/src/services/orderService.js` - Order business logic
- `server/src/services/pricingService.js` - Price calculations

**Admin Panel:**
- `client/admin-panel/src/pages/OrdersList.jsx` - Orders management
- `client/admin-panel/src/pages/OrderDetail.jsx` - Order details

**Customer Panel:**
- `client/customer-panel/src/pages/PlaceOrder.jsx` - Order creation
- `client/customer-panel/src/pages/OrdersList.jsx` - Order history
- `client/customer-panel/src/pages/OrderTracking.jsx` - Order tracking

**Flutter App:**
- `logistics_app/lib/presentation/pages/orders/orders_page.dart` - Driver orders

### Driver Management

**Server:**
- `server/src/routes/driverRoutes.js` - Driver endpoints

**Admin Panel:**
- `client/admin-panel/src/pages/DriversList.jsx` - Driver management

**Flutter App:**
- `logistics_app/lib/presentation/pages/profile/profile_page.dart` - Driver profile

### Financial Management

**Server:**
- `server/src/services/pricingService.js` - Payment calculations
- `server/database/schema.sql` - Wallet and transaction tables

**Admin Panel:**
- `client/admin-panel/src/pages/Dashboard.jsx` - Revenue statistics

**Flutter App:**
- `logistics_app/lib/presentation/pages/earnings/earnings_page.dart` - Wallet and earnings

---

## Configuration File Locations

### Environment Variables

| Component | File Location | Variables |
|-----------|--------------|-----------|
| Server | `logistics_system/.env` | `SUPABASE_*`, `PORT`, `REDIS_URL` |
| Admin Panel | `client/admin-panel/.env` | `VITE_SUPABASE_*`, `VITE_API_URL` |
| Customer Panel | `client/customer-panel/.env` | `VITE_SUPABASE_*`, `VITE_API_URL` |
| Flutter App | Build-time constants | `API_BASE_URL` (via `--dart-define`) |

### Build Configuration

| Component | File | Purpose |
|-----------|------|---------|
| Server | `server/package.json` | Dependencies, scripts |
| Admin Panel | `client/admin-panel/vite.config.js` | Vite build config |
| Admin Panel | `client/admin-panel/tailwind.config.js` | Tailwind CSS config |
| Customer Panel | `client/customer-panel/vite.config.js` | Vite build config |
| Customer Panel | `client/customer-panel/tailwind.config.js` | Tailwind CSS config |
| Flutter App | `logistics_app/pubspec.yaml` | Flutter dependencies |

### Deployment Configuration

| Component | File | Platform |
|-----------|------|----------|
| Server | `server/render.yaml` | Render.com |
| Admin Panel | `client/admin-panel/vercel.json` | Vercel |
| Customer Panel | `client/customer-panel/vercel.json` | Vercel |
| Flutter App | Build scripts | Manual APK/IPA |

---

## File Dependencies

### Server Dependencies

**`server.js` depends on:**
- All route files (`routes/*.js`)
- All middleware files (`middleware/*.js`)
- All service files (`services/*.js`)
- Utility files (`utils/*.js`)

**Route files depend on:**
- Controllers (`controllers/*.js`)
- Services (`services/*.js`)
- Middleware (`middleware/*.js`)

**Services depend on:**
- Supabase client (from `server.js`)
- Redis client (from `cacheService.js`)
- Utility functions (`utils/*.js`)

### React App Dependencies

**`App.jsx` depends on:**
- All page components (`pages/*.jsx`)
- Layout components (`components/*.jsx`)
- Context providers (`contexts/*.jsx`)
- Configuration (`config/*.js`)

**Page components depend on:**
- Context providers (for auth state)
- Configuration (for API URLs)
- Other components (for UI)

### Flutter App Dependencies

**`main.dart` depends on:**
- All page files (`presentation/pages/*.dart`)
- Providers (`presentation/providers/*.dart`)
- Services (`core/services/*.dart`)
- Configuration (`core/config/*.dart`)

**Page files depend on:**
- Providers (for state)
- Services (for API calls)
- Theme (for styling)
- Utils (for responsive design)

---

## File Modification Guidelines

### Safe to Modify

**Frontend Pages:**
- `client/*/src/pages/*.jsx` - Page components (UI changes)
- `logistics_app/lib/presentation/pages/*.dart` - Screen components

**Styling:**
- `client/*/src/index.css` - Global styles
- `client/*/tailwind.config.js` - Tailwind configuration
- `logistics_app/lib/core/theme/app_theme.dart` - Flutter theme

**Configuration:**
- `.env` files - Environment variables
- `vite.config.js` - Build configuration
- `pubspec.yaml` - Flutter dependencies

### Modify with Caution

**Core Services:**
- `server/src/services/*.js` - Business logic changes
- `logistics_app/lib/core/services/*.dart` - API service changes

**Routes:**
- `server/src/routes/*.js` - API endpoint changes
- `client/*/src/App.jsx` - Route definitions

**Database:**
- `server/database/schema.sql` - Schema changes require migrations
- `server/database/rls_policies.sql` - Security policy changes

### Do Not Modify Without Understanding

**Core Infrastructure:**
- `server/src/server.js` - Main server setup
- `server/src/middleware/auth.js` - Authentication logic
- `logistics_app/lib/main.dart` - App initialization

**Database Schema:**
- Table structures - Changes affect all components
- Foreign key constraints - Changes affect data integrity
- RLS policies - Changes affect security

---

**End of README7.md**

**Next Section:** README8.md will cover the Security Model in detail.
