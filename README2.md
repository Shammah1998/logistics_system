# Logistics Platform - Core Components: Server/Backend

## Core Components (DEEP DIVE) - Server/Backend

The server is the heart of the Logistics Platform, built with Express.js and Node.js. It serves as the API layer that connects all client applications (Admin Panel, Customer Panel, and Driver Mobile App) to the Supabase PostgreSQL database. This section provides a comprehensive deep dive into every component of the server architecture.

---

## Server Directory Structure

```
server/
├── src/
│   ├── server.js              # Main entry point, Express app setup
│   ├── controllers/           # Request handlers (business logic entry points)
│   │   └── orderController.js
│   ├── middleware/            # Express middleware (auth, errors, rate limiting)
│   │   ├── auth.js
│   │   ├── errorHandler.js
│   │   └── rateLimiter.js
│   ├── repositories/         # Data access layer (database queries)
│   │   └── orderRepository.js
│   ├── routes/                # API route definitions
│   │   ├── authRoutes.js
│   │   ├── orderRoutes.js
│   │   ├── driverRoutes.js
│   │   ├── customerRoutes.js
│   │   ├── dashboardRoutes.js
│   │   ├── adminRoutes.js
│   │   └── podRoutes.js
│   ├── services/             # Business logic layer
│   │   ├── orderService.js
│   │   ├── pricingService.js
│   │   └── cacheService.js
│   └── utils/                 # Utility functions
│       ├── logger.js
│       └── mapsService.js
├── database/                  # Database schema and migrations
│   ├── schema.sql
│   ├── rls_policies.sql
│   └── [migration files]
├── scripts/                   # Utility scripts
│   ├── create-admin.js
│   └── check-admin-user.js
├── logs/                      # Log files (development only)
│   ├── combined.log
│   └── error.log
├── package.json
└── render.yaml                 # Render.com deployment config
```

---

## Main Entry Point: `server.js`

**File:** `server/src/server.js`

**Purpose:** This is the application's entry point. It initializes the Express server, configures middleware, sets up routes, and establishes connections to Supabase and Redis.

**What It Does:**
1. **Environment Variable Validation**: Checks for required Supabase credentials on startup
2. **Supabase Client Initialization**: Creates Supabase client with service role key (bypasses RLS)
3. **Express App Setup**: Configures Express with security middleware
4. **CORS Configuration**: Allows requests from admin panel, customer panel, and mobile apps
5. **Route Registration**: Mounts all API route handlers
6. **Error Handling**: Sets up global error handler
7. **Server Startup**: Starts listening on configured port (default: 3000)
8. **Redis Cache Initialization**: Connects to Redis (optional, server works without it)

**Key Code Sections:**

```javascript
// Environment validation - fails fast if config is missing
const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
const missingEnvVars = requiredEnvVars.filter(varName => !process.env[varName]);
if (missingEnvVars.length > 0) {
  console.error('❌ Missing required environment variables:');
  process.exit(1);
}

// Supabase client with service role key (bypasses RLS)
export const supabase = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'public' },
  auth: {
    persistSession: false,  // Backend doesn't need session persistence
    autoRefreshToken: false // Backend doesn't need token refresh
  }
});

// CORS configuration - allows multiple origins
app.use(cors({
  origin: function(origin, callback) {
    // Allows localhost in development, specific URLs in production
    // Also allows *.vercel.app for preview deployments
  },
  credentials: true
}));

// Health check endpoint (before rate limiting)
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    cache: cache.isAvailable() ? 'connected' : 'disconnected'
  });
});

// Rate limiting applied after health check
app.use(rateLimiter);

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/drivers', driverRoutes);
// ... more routes
```

**Why It's Structured This Way:**
- **Service Role Key**: Backend uses service role key to bypass Row Level Security (RLS) because the backend is trusted and needs to perform operations that RLS would restrict (e.g., admin operations, cross-user queries)
- **CORS Configuration**: Allows multiple origins because we have three different client applications (admin panel, customer panel, mobile app)
- **Health Check Before Rate Limiting**: Health checks should never be rate-limited, so they're registered before the rate limiter middleware
- **Graceful Redis Failure**: Server continues to work even if Redis is unavailable (cache just won't be used)

---

## Middleware Layer

Middleware functions process requests before they reach route handlers. They handle cross-cutting concerns like authentication, error handling, and rate limiting.

### Authentication Middleware: `middleware/auth.js`

**Purpose:** Verifies JWT tokens and extracts user information for authorization decisions.

**What It Does:**
1. **Token Extraction**: Extracts JWT token from `Authorization: Bearer <token>` header
2. **Token Verification**: Verifies token with Supabase Auth API
3. **User Type Lookup**: Fetches user_type from `users` table
4. **Request Enrichment**: Attaches user object to `req.user` for use in route handlers

**Key Functions:**

**`authenticate(req, res, next)`**
- Extracts token from Authorization header
- Verifies token with `supabase.auth.getUser(token)`
- Fetches user_type from database
- Attaches `{ id, email, user_type }` to `req.user`
- Returns 401 if token is missing or invalid

**`requireUserType(...allowedTypes)`**
- Returns a middleware function that checks if `req.user.user_type` is in allowedTypes
- Returns 403 if user type is not allowed
- Used like: `router.use(requireUserType('admin'))`

**Why This Design:**
- **Separate Functions**: `authenticate` verifies identity, `requireUserType` checks permissions - separation of concerns
- **Database Lookup for User Type**: User type is stored in database, not in JWT token, allowing admins to change user types without invalidating tokens
- **Reusable**: Can be applied to individual routes or entire route groups

**Usage Example:**
```javascript
// All routes in this router require authentication
router.use(authenticate);

// Only admins can access this route
router.get('/drivers', requireUserType('admin'), async (req, res) => {
  // req.user is available here
  const userId = req.user.id;
  const userType = req.user.user_type; // 'admin'
});
```

### Error Handler Middleware: `middleware/errorHandler.js`

**Purpose:** Centralized error handling for consistent error responses across all routes.

**What It Does:**
1. **Error Logging**: Logs all errors with context (path, method, stack trace)
2. **Error Classification**: Identifies error types (ValidationError, Supabase errors)
3. **Response Formatting**: Returns consistent error response format
4. **Security**: Hides stack traces in production

**Error Types Handled:**
- **ValidationError**: Returns 400 with validation details
- **Supabase Errors (PGRST codes)**: Returns 400 with database error message
- **Default Errors**: Returns 500 with generic message in production, detailed message in development

**Why Centralized:**
- **Consistency**: All errors follow the same format: `{ success: false, message: "..." }`
- **Security**: Stack traces only shown in development
- **Logging**: All errors are logged in one place for monitoring

### Rate Limiter Middleware: `middleware/rateLimiter.js`

**Purpose:** Prevents API abuse by limiting requests per IP address.

**What It Does:**
1. **Request Counting**: Tracks requests per IP in a 15-minute window
2. **Limit Enforcement**: Blocks requests after 100 requests (production) or 1000 (development)
3. **Health Check Exclusion**: Never rate-limits `/health` endpoint
4. **Localhost Exclusion**: Skips rate limiting for localhost in development

**Configuration:**
- **Window**: 15 minutes
- **Max Requests**: 100 (production), 1000 (development)
- **Message**: Returns `{ success: false, message: "Too many requests..." }`

**Why This Design:**
- **IP-Based**: Simple and effective for preventing abuse
- **Higher Limit in Development**: Developers need to test without hitting limits
- **Health Check Exclusion**: Monitoring tools can check health without limits

---

## Route Handlers

Routes define the API endpoints and connect HTTP requests to business logic.

### Authentication Routes: `routes/authRoutes.js`

**Purpose:** Handles driver login, token verification, and logout.

**Endpoints:**

**`POST /api/auth/drivers/login`**
- **Purpose**: Authenticates drivers using phone number and PIN
- **Request Body**: `{ phone: string, password: string }`
- **Process**:
  1. Normalizes phone number to +254 format
  2. Generates expected email: `driver_<phone>@drivers.xobo.co.ke`
  3. Attempts Supabase Auth sign-in
  4. Creates user record if missing (auto-fix)
  5. Checks driver status (blocks inactive/blocked drivers)
  6. Returns user data and JWT token
- **Response**: `{ success: true, data: { user: {...}, token: "..." } }`

**Why Phone-to-Email Mapping:**
- Supabase Auth requires email addresses
- Drivers use phone numbers for login
- Solution: Generate deterministic email from phone number
- Format ensures uniqueness and matches driver creation logic

**`GET /api/auth/verify`**
- **Purpose**: Verifies if a JWT token is still valid
- **Headers**: `Authorization: Bearer <token>`
- **Process**: Verifies token with Supabase, fetches user data
- **Response**: `{ success: true, data: { user: {...} } }`

**`POST /api/auth/logout`**
- **Purpose**: Logout endpoint (mainly for API consistency)
- **Note**: JWT tokens are stateless, so logout is handled client-side by removing token

### Order Routes: `routes/orderRoutes.js`

**Purpose:** Handles all order-related operations (create, read, update, assign).

**Endpoints:**

**`GET /api/orders`**
- **Purpose**: Lists orders with filtering and pagination
- **Authentication**: Required
- **Authorization**: 
  - Customers see only their orders
  - Drivers see only assigned orders
  - Admins see all orders
- **Query Parameters**: `status`, `limit`, `offset`
- **Caching**: Results cached for 15 seconds
- **Process**:
  1. Checks cache first
  2. If cache miss, queries database with user-specific filters
  3. Formats response with customer/driver info
  4. Stores in cache
  5. Returns paginated results

**`POST /api/orders/create`**
- **Purpose**: Creates a new order
- **Authentication**: Required (customer or admin)
- **Validation**: Uses `validateCreateOrder` middleware
- **Process**:
  1. Validates request body (addresses, coordinates, items)
  2. Calls `orderController.createOrder`
  3. Invalidates order and dashboard caches
  4. Returns created order
- **Cache Invalidation**: Clears all order-related caches

**`GET /api/orders/:orderId`**
- **Purpose**: Gets detailed order information
- **Authentication**: Required
- **Authorization**: Customer (own orders), Driver (assigned orders), Admin (all orders)
- **Caching**: Results cached for 30 seconds
- **Response**: Complete order with items, drops, customer, driver info

**`PATCH /api/orders/:orderId/status`**
- **Purpose**: Updates order status
- **Authentication**: Required (admin or driver)
- **Request Body**: `{ status: "pending" | "assigned" | "in_transit" | "delivered" | "cancelled" }`
- **Cache Invalidation**: Clears order detail and list caches

**`PATCH /api/orders/:orderId/assign`**
- **Purpose**: Assigns an order to a driver
- **Authentication**: Required (admin only)
- **Request Body**: `{ driverId: "uuid" }`
- **Process**:
  1. Verifies driver exists and is active
  2. Updates order with driver_id and status="assigned"
  3. Invalidates caches
- **Cache Invalidation**: Clears order and dashboard caches

### Driver Routes: `routes/driverRoutes.js`

**Purpose:** Handles driver management (admin operations) and driver self-service endpoints.

**Admin Endpoints:**

**`GET /api/drivers`**
- **Purpose**: Lists all drivers with wallet balances
- **Authentication**: Required (admin only)
- **Caching**: Results cached for 60 seconds
- **Response**: Array of drivers with user info, vehicle details, wallet balance

**`POST /api/drivers`**
- **Purpose**: Creates a new driver account
- **Authentication**: Required (admin only)
- **Request Body**: `{ fullName, phone, pin, vehicleType, vehicleRegistration, licenseNumber }`
- **Process**:
  1. Validates phone number and PIN (4-6 digits)
  2. Checks if phone already exists
  3. Creates Supabase Auth user with generated email
  4. Creates user record in `users` table
  5. Creates driver record in `drivers` table
  6. Creates wallet record (auto-created by trigger, but explicit for safety)
  7. Stores PIN hash in `driver_credentials` table (optional, Supabase Auth is primary)
  8. Invalidates driver cache
- **Why Multiple Steps**: Ensures data consistency - if any step fails, previous steps are rolled back

**`PUT /api/drivers/:driverId`**
- **Purpose**: Updates driver information
- **Authentication**: Required (admin only)
- **Request Body**: `{ fullName?, phone?, pin?, vehicleType?, status?, ... }`
- **Process**: Updates user and driver records, updates PIN in Supabase Auth if provided

**`DELETE /api/drivers/:driverId`**
- **Purpose**: Deletes a driver account
- **Authentication**: Required (admin only)
- **Process**: Deletes from Supabase Auth (cascades to users and drivers tables)

**Driver Self-Service Endpoints:**

**`GET /api/drivers/me/profile`**
- **Purpose**: Gets driver's own profile and wallet
- **Authentication**: Required (driver)
- **Caching**: Results cached for 300 seconds (5 minutes)
- **Response**: User info, driver info, wallet balance

**`GET /api/drivers/me/orders`**
- **Purpose**: Gets driver's assigned orders
- **Authentication**: Required (driver)
- **Query Parameters**: `status` (optional filter)
- **Caching**: Results cached for 15 seconds

**`GET /api/drivers/me/wallet`**
- **Purpose**: Gets driver's wallet balance and transaction history
- **Authentication**: Required (driver)
- **Caching**: Results cached for 60 seconds
- **Response**: `{ balance, pendingBalance, totalEarned, transactions: [...] }`

**`POST /api/drivers/me/withdraw`**
- **Purpose**: Creates a withdrawal request
- **Authentication**: Required (driver)
- **Request Body**: `{ amount: number, phoneNumber: string }`
- **Process**:
  1. Validates amount (must be positive, less than balance)
  2. Creates withdrawal_request record with status="pending"
  3. Invalidates wallet cache
- **Note**: Actual payment processing is handled by admin (manual or automated)

### Customer Routes: `routes/customerRoutes.js`

**Purpose:** Handles customer data retrieval (admin operations).

**Endpoints:**

**`GET /api/customers`**
- **Purpose**: Lists all customers with order statistics
- **Authentication**: Required (admin only)
- **Caching**: Results cached for 120 seconds (2 minutes)
- **Response**: Array of customers with order count, total spent, pending orders

**`GET /api/customers/:customerId`**
- **Purpose**: Gets detailed customer information
- **Authentication**: Required (admin only)
- **Response**: Customer info with recent orders

### Dashboard Routes: `routes/dashboardRoutes.js`

**Purpose:** Provides statistics and analytics for admin dashboard.

**Endpoints:**

**`GET /api/dashboard/stats`**
- **Purpose**: Returns aggregated statistics for dashboard
- **Authentication**: Required (admin only)
- **Caching**: Results cached for 30 seconds
- **Response**: 
  ```json
  {
    orders: { total, today, pending, assigned, inTransit, delivered, cancelled },
    drivers: { total, active },
    customers: { total },
    revenue: { total, monthly },
    pods: { pending }
  }
  ```
- **Optimization**: Uses parallel queries and aggregation functions for performance

**`GET /api/dashboard/activity`**
- **Purpose**: Returns recent activity feed
- **Authentication**: Required (admin only)
- **Caching**: Results cached for 15 seconds
- **Response**: Array of recent orders with customer info

### Admin Routes: `routes/adminRoutes.js`

**Purpose:** Provides admin-only system management endpoints.

**Endpoints:**

**`GET /api/admin/cache/status`**
- **Purpose**: Checks Redis cache connection status
- **Authentication**: Required (admin only)
- **Response**: `{ connected: true/false, message: "..." }`

**`POST /api/admin/cache/clear`**
- **Purpose**: Clears all caches
- **Authentication**: Required (admin only)
- **Process**: Invalidates all cache entities (dashboard, orders, drivers, customers, user, wallet)

**`POST /api/admin/cache/clear/:entity`**
- **Purpose**: Clears cache for a specific entity
- **Authentication**: Required (admin only)
- **Parameters**: `entity` (dashboard, orders, drivers, customers, user, wallet)

**`GET /api/admin/health`**
- **Purpose**: Returns system health information
- **Authentication**: Required (admin only)
- **Response**: Server status, cache status, uptime, memory usage

### POD Routes: `routes/podRoutes.js`

**Purpose:** Handles proof of delivery operations (currently placeholder endpoints).

**Endpoints:**

**`POST /api/pods/upload`**
- **Purpose**: Uploads proof of delivery (placeholder)
- **Authentication**: Required (driver only)
- **Note**: Implementation pending

**`POST /api/pods/:podId/approve`**
- **Purpose**: Approves or rejects a POD (placeholder)
- **Authentication**: Required (admin only)
- **Note**: Implementation pending

---

## Services Layer

Services contain business logic that is independent of HTTP requests. They can be reused across different routes and controllers.

### Order Service: `services/orderService.js`

**Purpose:** Handles order creation and retrieval business logic.

**Key Functions:**

**`createOrder(orderData, customerId)`**
- Validates order data
- Generates order number
- Creates order record
- Creates order items
- Creates drops
- Returns complete order object

**`getOrderById(orderId)`**
- Fetches order with all related data (items, drops, customer, driver)
- Handles authorization (checks if user can access order)
- Returns formatted order object

**Why Separate Service:**
- **Reusability**: Can be called from different routes (REST API, webhooks, background jobs)
- **Testability**: Business logic can be tested without HTTP layer
- **Separation of Concerns**: Routes handle HTTP, services handle business logic

### Pricing Service: `services/pricingService.js`

**Purpose:** Calculates order prices based on pricing mode and price cards.

**Key Functions:**

**`getPriceCard(companyId, vehicleType, pricingMode)`**
- Fetches applicable price card from database
- Priority: Company-specific card → Default card (company_id is NULL)
- Returns price card with base_price, price_per_km, price_per_box, min_price

**`calculateOrderPrice(orderData, companyId, vehicleType, pricingMode)`**
- Gets price card
- If distance_based: Calculates distance using Google Maps API, applies formula: `base_price + (distance × price_per_km)`
- If per_box: Sums item prices: `Σ(quantity × unit_price)`
- Applies minimum price if calculated price is lower
- Returns: `{ base_price, total_distance_km, total_price, price_card_id }`

**`calculateDriverPayment(grossAmount)`**
- Calculates driver net payment after deductions
- Deductions:
  - Commission: `grossAmount × (PLATFORM_COMMISSION_PERCENT / 100)` (default: 10%)
  - Insurance: `grossAmount × (INSURANCE_PERCENT / 100)` (default: 2%)
  - Withholding Tax: `grossAmount × (WITHHOLDING_TAX_PERCENT / 100)` (default: 5%)
- Returns: `{ gross_amount, commission, insurance, withholding_tax, net_amount }`

**Why This Design:**
- **Flexible Pricing**: Supports both distance-based and per-box pricing
- **Company-Specific Pricing**: Corporate customers can have custom rates
- **Configurable Deductions**: Percentages can be adjusted via environment variables

### Cache Service: `services/cacheService.js`

**Purpose:** Provides Redis caching functionality with graceful degradation.

**Key Features:**
- **Connection Management**: Handles Redis connection with retry logic
- **Graceful Degradation**: Server works without Redis (just slower)
- **TTL Management**: Different cache durations for different data types
- **Pattern-Based Invalidation**: Can invalidate all keys matching a pattern

**Key Functions:**

**`connect()`**
- Attempts to connect to Redis
- Supports multiple connection formats (URL, host/port/password)
- Handles TLS for Redis Cloud
- Returns false if connection fails (doesn't throw)

**`getOrSet(key, fetchFunction, ttl)`**
- Checks cache first
- If cache hit: Returns cached data
- If cache miss: Calls fetchFunction, stores result in cache, returns data
- This is the most commonly used function

**`invalidateEntity(entity)`**
- Deletes all cache keys matching pattern: `logistics:{entity}:*`
- Used when data changes (e.g., order created → invalidate orders cache)

**Cache TTL Configuration:**
- Dashboard stats: 30 seconds (frequently changing)
- Orders list: 15 seconds (changes often)
- Drivers list: 60 seconds (changes less frequently)
- Customers list: 120 seconds (rarely changes)
- User profile: 300 seconds (5 minutes, static data)
- Wallet: 60 seconds (balance changes with transactions)

**Why Redis:**
- **Performance**: Reduces database load for frequently accessed data
- **Scalability**: Can handle high request volumes
- **Optional**: System works without it (important for development)

---

## Controllers

Controllers are the entry point for business logic from HTTP requests. They validate input, call services, and format responses.

### Order Controller: `controllers/orderController.js`

**Purpose:** Handles HTTP-specific order operations.

**Key Functions:**

**`validateCreateOrder` (Middleware)**
- Validates request body using express-validator
- Checks: vehicle_type, pricing_mode, addresses, coordinates, items
- Returns 400 with validation errors if invalid

**`createOrder(req, res, next)`**
- Extracts customer ID from `req.user.id`
- Validates request (already done by middleware)
- Calls `orderService.createOrder(orderData, customerId)`
- Returns 201 Created with order data

**`getOrderById(req, res, next)`**
- Extracts orderId from `req.params`
- Calls `orderService.getOrderById(orderId)`
- Returns 200 OK with order data or 404 if not found

**Why Controllers:**
- **HTTP-Specific Logic**: Handles request/response formatting
- **Error Handling**: Catches errors and passes to error handler middleware
- **Separation**: Routes define endpoints, controllers handle request processing

---

## Repositories

Repositories abstract database access, making it easier to change database implementations.

### Order Repository: `repositories/orderRepository.js`

**Purpose:** Provides database access methods for orders.

**Note:** Currently, most database queries are done directly in services using Supabase client. The repository pattern is partially implemented and can be extended for better separation of concerns.

**Future Enhancement:** Move all Supabase queries to repositories for better testability and maintainability.

---

## Utilities

Utility functions provide reusable functionality across the application.

### Logger: `utils/logger.js`

**Purpose:** Centralized logging using Winston.

**Features:**
- **Console Logging**: Always logs to console with colors
- **File Logging**: Logs to files in development (not in production - Render has ephemeral filesystem)
- **Log Levels**: info, warn, error
- **Structured Logging**: Supports metadata objects

**Usage:**
```javascript
logger.info('Order created', { orderId, customerId });
logger.error('Database error', { error: error.message, stack: error.stack });
```

**Why Winston:**
- **Structured Logging**: Better than console.log for production
- **Multiple Transports**: Can log to console, files, external services
- **Log Levels**: Can filter logs by severity

### Maps Service: `utils/mapsService.js`

**Purpose:** Integrates with Google Maps API for distance calculation.

**Key Functions:**

**`calculateDistance(pickupAddress, drops)`**
- Uses Google Maps Distance Matrix API
- Calculates distance from pickup to all drop locations
- Returns total distance in kilometers
- Handles multiple drops (sums distances)

**Why Google Maps:**
- **Accurate Routing**: Uses real road distances, not straight-line
- **Multi-Drop Support**: Can calculate optimal routes
- **Reliable**: Industry-standard API

---

## How Components Interact

### Request Flow Example: Creating an Order

```
1. HTTP Request arrives at Express server
   ↓
2. CORS middleware checks origin
   ↓
3. Rate limiter checks request count
   ↓
4. Authentication middleware (auth.js)
   - Extracts JWT token
   - Verifies with Supabase Auth
   - Fetches user_type from database
   - Attaches user to req.user
   ↓
5. requireUserType('customer', 'admin') checks user_type
   ↓
6. validateCreateOrder middleware validates request body
   ↓
7. orderRoutes.js receives request
   ↓
8. orderController.createOrder called
   ↓
9. orderService.createOrder called
   - Validates order data
   - Calls pricingService.calculateOrderPrice
     - Gets price card from database
     - Calculates distance (if distance_based)
     - Calculates price
   - Creates order in database
   - Creates order items
   - Creates drops
   ↓
10. cacheService.invalidateEntity('orders') clears caches
   ↓
11. Response sent to client
```

### Data Flow: Dashboard Stats

```
1. Admin requests /api/dashboard/stats
   ↓
2. cacheService.getOrSet called
   - Checks Redis cache first
   ↓
3. If cache miss:
   - dashboardRoutes.js calls fetchDashboardStats()
   - Runs parallel database queries:
     * Count orders
     * Count orders by status
     * Count drivers
     * Sum revenue
     * etc.
   - Aggregates results
   - Stores in Redis cache (30 second TTL)
   ↓
4. Returns cached or fresh data
```

---

**End of README2.md**

**Next Section:** README3.md will cover the Admin Panel and Customer Panel React applications in detail.
