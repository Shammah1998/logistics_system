# Logistics Platform - API Endpoints & Routing Logic

## API / Routing Logic

This section documents all API endpoints, their request/response formats, authentication requirements, and the routing logic that connects requests to handlers. The API follows RESTful principles and uses JWT authentication.

---

## Base URL

**Development:**
```
http://localhost:3000/api
```

**Production:**
```
https://your-backend.onrender.com/api
```

---

## Authentication

### How Authentication Works

All API endpoints (except `/api/auth/drivers/login` and `/health`) require authentication via JWT token.

**Request Format:**
```
Authorization: Bearer <jwt-token>
```

**Token Source:**
- **Web Apps:** Token from Supabase Auth session (stored in localStorage)
- **Mobile App:** Token from `/api/auth/drivers/login` response (stored in SharedPreferences)

**Token Verification:**
- Backend verifies token with Supabase Auth API
- Fetches `user_type` from database
- Attaches `{ id, email, user_type }` to `req.user`

**Error Responses:**
- **401 Unauthorized:** Missing or invalid token
- **403 Forbidden:** Valid token but insufficient permissions

---

## Response Format

### Success Response

```json
{
  "success": true,
  "data": { ... },
  "_meta": {
    "cached": false
  }
}
```

### Error Response

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error (development only)"
}
```

### Pagination Response

```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 100,
    "hasMore": true
  }
}
```

---

## Endpoint Categories

1. **Authentication** (`/api/auth`)
2. **Orders** (`/api/orders`)
3. **Drivers** (`/api/drivers`)
4. **Customers** (`/api/customers`)
5. **Dashboard** (`/api/dashboard`)
6. **Admin** (`/api/admin`)
7. **PODs** (`/api/pods`)

---

## 1. Authentication Endpoints

### POST `/api/auth/drivers/login`

**Purpose:** Driver login with phone number and PIN.

**Authentication:** Not required (public endpoint)

**Request Body:**
```json
{
  "phone": "0712345678",
  "password": "1234"
}
```

**Phone Number Formats Accepted:**
- `0712345678` (Kenyan format)
- `712345678` (without leading 0)
- `+254712345678` (international format)

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "driver_254712345678@drivers.xobo.co.ke",
      "fullName": "John Driver",
      "phone": "+254712345678",
      "userType": "driver",
      "vehicleType": "small",
      "status": "active"
    },
    "token": "jwt-access-token",
    "refreshToken": "jwt-refresh-token"
  }
}
```

**Response (Error - 401):**
```json
{
  "success": false,
  "message": "Invalid phone number or PIN."
}
```

**Response (Error - 403):**
```json
{
  "success": false,
  "message": "Your account has been blocked. Please contact support."
}
```

**How It Works:**
1. Normalizes phone number to `+254` format
2. Generates expected email: `driver_<phone>@drivers.xobo.co.ke`
3. Authenticates with Supabase Auth
4. Creates missing `public.users` record if needed
5. Checks driver status (blocks inactive/blocked drivers)
6. Returns JWT token and user data

---

### GET `/api/auth/verify`

**Purpose:** Verify JWT token validity and get user information.

**Authentication:** Required (token in Authorization header)

**Request Headers:**
```
Authorization: Bearer <token>
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "fullName": "User Name",
      "phone": "+254712345678",
      "userType": "customer" | "admin" | "driver"
    }
  }
}
```

**Response (Error - 401):**
```json
{
  "success": false,
  "message": "Invalid or expired token"
}
```

**How It Works:**
1. Extracts token from Authorization header
2. Verifies token with Supabase Auth
3. Fetches user data from `users` table
4. Returns user information

---

### POST `/api/auth/logout`

**Purpose:** Logout endpoint (placeholder - logout handled client-side).

**Authentication:** Required

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

**Note:** JWT tokens are stateless. Logout is handled by removing token from client storage.

---

## 2. Order Endpoints

### GET `/api/orders`

**Purpose:** Get list of orders (filtered by user type).

**Authentication:** Required

**Authorization:**
- **Admin:** Sees all orders
- **Customer:** Sees own orders only
- **Driver:** Sees assigned orders only

**Query Parameters:**
- `status` (optional): Filter by status (`pending`, `assigned`, `in_transit`, `delivered`, `cancelled`)
- `limit` (optional): Number of records per page (default: 50, max: 100)
- `offset` (optional): Pagination offset (default: 0)

**Example Request:**
```
GET /api/orders?status=pending&limit=20&offset=0
Authorization: Bearer <token>
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "orderNumber": "ORD12345",
      "pickupAddress": {
        "address": "123 Main St",
        "coordinates": { "lat": -1.2921, "lng": 36.8219 }
      },
      "totalAmount": 1500.00,
      "totalDistance": 25.5,
      "status": "pending",
      "vehicleType": "small",
      "createdAt": "2024-01-01T12:00:00Z",
      "customer": {
        "id": "uuid",
        "name": "John Customer",
        "phone": "+254712345678",
        "email": "customer@example.com"
      },
      "driver": null,
      "drops": [
        {
          "id": "uuid",
          "recipientName": "Jane Doe",
          "address": "456 Oak Ave",
          "phone": "+254798765432",
          "status": "pending"
        }
      ],
      "dropCount": 1
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 100,
    "hasMore": true
  },
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 15 seconds
- **Key:** `orders:<userType>:<userId|all>:<status>:<limit>:<offset>`
- **Invalidated:** On order create/update/delete

---

### GET `/api/orders/my/orders`

**Purpose:** Get customer's own orders (alias for customers).

**Authentication:** Required

**Authorization:** Customer only (implicit - filters by `customer_id`)

**Query Parameters:**
- `status` (optional): Filter by status
- `limit` (optional): Number of records (default: 50, max: 100)

**Response:** Same format as `GET /api/orders`

**Caching:**
- **TTL:** 15 seconds
- **Key:** `orders:my:<customerId>:<status>:<limit>`

---

### POST `/api/orders/create`

**Purpose:** Create a new order.

**Authentication:** Required

**Authorization:** Customer or Admin

**Request Body:**
```json
{
  "pickupAddress": {
    "address": "123 Main St, Nairobi",
    "coordinates": {
      "lat": -1.2921,
      "lng": 36.8219
    }
  },
  "drops": [
    {
      "recipientName": "Jane Doe",
      "address": "456 Oak Ave, Nairobi",
      "coordinates": {
        "lat": -1.3000,
        "lng": 36.8000
      },
      "recipientPhone": "+254798765432",
      "notes": "Call before delivery"
    }
  ],
  "vehicleType": "small",
  "pricingMode": "distance_based",
  "notes": "Fragile items"
}
```

**Validation:**
- `pickupAddress` required
- `drops` array required (at least 1 drop)
- `vehicleType` must be: `small`, `medium`, or `large`
- `pricingMode` must be: `distance_based` or `per_box`

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "id": "uuid",
    "orderNumber": "ORD12345",
    "totalPrice": 1500.00,
    "status": "pending"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Validation error",
  "errors": [
    {
      "field": "pickupAddress",
      "message": "Pickup address is required"
    }
  ]
}
```

**How It Works:**
1. Validates request body
2. Calculates distance using Google Maps API
3. Calculates price using pricing service
4. Creates order record
5. Creates drop records
6. Invalidates orders cache
7. Returns created order

**Cache Invalidation:**
- Invalidates `orders` cache
- Invalidates `dashboard` cache

---

### GET `/api/orders/:orderId`

**Purpose:** Get order details by ID.

**Authentication:** Required

**Authorization:**
- **Admin:** Can view any order
- **Customer:** Can view own orders only
- **Driver:** Can view assigned orders only

**URL Parameters:**
- `orderId`: Order UUID

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "orderNumber": "ORD12345",
    "pickupAddress": { ... },
    "drops": [ ... ],
    "totalPrice": 1500.00,
    "totalDistance": 25.5,
    "status": "pending",
    "vehicleType": "small",
    "customer": { ... },
    "driver": null,
    "createdAt": "2024-01-01T12:00:00Z",
    "updatedAt": "2024-01-01T12:00:00Z"
  },
  "_meta": {
    "cached": false
  }
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "message": "Order not found"
}
```

**Caching:**
- **TTL:** 60 seconds
- **Key:** `orders:detail:<orderId>`

---

### PATCH `/api/orders/:orderId/status`

**Purpose:** Update order status.

**Authentication:** Required

**Authorization:** Admin or Driver

**URL Parameters:**
- `orderId`: Order UUID

**Request Body:**
```json
{
  "status": "in_transit"
}
```

**Valid Statuses:**
- `pending`
- `assigned`
- `in_transit`
- `delivered`
- `cancelled`

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Order status updated",
  "data": {
    "id": "uuid",
    "status": "in_transit",
    "updatedAt": "2024-01-01T12:00:00Z"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Invalid status. Must be one of: pending, assigned, in_transit, delivered, cancelled"
}
```

**Cache Invalidation:**
- Invalidates order detail cache
- Invalidates orders list cache
- Invalidates dashboard cache

---

### PATCH `/api/orders/:orderId/assign`

**Purpose:** Assign driver to order.

**Authentication:** Required

**Authorization:** Admin only

**URL Parameters:**
- `orderId`: Order UUID

**Request Body:**
```json
{
  "driverId": "driver-uuid"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Driver assigned successfully",
  "data": {
    "id": "uuid",
    "driverId": "driver-uuid",
    "status": "assigned"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Driver is not active"
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "message": "Driver not found"
}
```

**How It Works:**
1. Validates driver exists
2. Checks driver is active
3. Updates order with `driver_id` and sets status to `assigned`
4. Invalidates caches

**Cache Invalidation:**
- Invalidates order detail cache
- Invalidates orders list cache
- Invalidates dashboard cache

---

## 3. Driver Endpoints

### GET `/api/drivers`

**Purpose:** Get list of all drivers (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "John Driver",
      "phone": "+254712345678",
      "email": "driver_254712345678@drivers.xobo.co.ke",
      "status": "active",
      "vehicleType": "small",
      "vehicleRegistration": "KCA 123A",
      "licenseNumber": "DL12345",
      "balance": 5000.00,
      "createdAt": "2024-01-01T12:00:00Z",
      "hasUserRecord": true
    }
  ],
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 60 seconds
- **Key:** `drivers:list`

---

### POST `/api/drivers`

**Purpose:** Create a new driver (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Request Body:**
```json
{
  "fullName": "John Driver",
  "phone": "0712345678",
  "pin": "1234",
  "vehicleType": "small",
  "vehicleRegistration": "KCA 123A",
  "licenseNumber": "DL12345"
}
```

**Validation:**
- `fullName`, `phone`, `pin` required
- `pin` must be 4-6 digits
- `phone` must be valid format

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "Driver created successfully",
  "data": {
    "id": "uuid",
    "name": "John Driver",
    "phone": "+254712345678",
    "email": "driver_254712345678@drivers.xobo.co.ke",
    "vehicleType": "small",
    "status": "active"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "A user with this phone number already exists"
}
```

**How It Works:**
1. Normalizes phone number
2. Checks phone doesn't exist
3. Creates Supabase Auth user (email: `driver_<phone>@drivers.xobo.co.ke`)
4. Creates `users` record
5. Creates `drivers` record
6. Creates `wallets` record (balance: 0)
7. Invalidates drivers cache

**Cache Invalidation:**
- Invalidates `drivers` cache
- Invalidates `dashboard` cache

---

### PUT `/api/drivers/:driverId`

**Purpose:** Update driver information (admin only).

**Authentication:** Required

**Authorization:** Admin only

**URL Parameters:**
- `driverId`: Driver UUID

**Request Body:**
```json
{
  "fullName": "John Updated",
  "phone": "+254712345678",
  "pin": "5678",
  "vehicleType": "medium",
  "vehicleRegistration": "KCB 456B",
  "licenseNumber": "DL67890",
  "status": "active"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Driver updated successfully"
}
```

**Cache Invalidation:**
- Invalidates `drivers` cache
- Invalidates user profile cache

---

### DELETE `/api/drivers/:driverId`

**Purpose:** Delete a driver (admin only).

**Authentication:** Required

**Authorization:** Admin only

**URL Parameters:**
- `driverId`: Driver UUID

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Driver deleted successfully"
}
```

**How It Works:**
1. Deletes Supabase Auth user
2. Cascades delete to `users`, `drivers`, `wallets` tables
3. Invalidates caches

**Cache Invalidation:**
- Invalidates `drivers` cache
- Invalidates `dashboard` cache

---

### GET `/api/drivers/me/profile`

**Purpose:** Get driver's own profile.

**Authentication:** Required

**Authorization:** Driver only (implicit - uses `req.user.id`)

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "driver_254712345678@drivers.xobo.co.ke",
    "phone": "+254712345678",
    "fullName": "John Driver",
    "vehicleType": "small",
    "vehicleRegistration": "KCA 123A",
    "licenseNumber": "DL12345",
    "status": "active",
    "wallet": {
      "balance": 5000.00,
      "pendingBalance": 1000.00,
      "totalEarned": 15000.00
    }
  },
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 300 seconds (5 minutes)
- **Key:** `user:<driverId>:profile`

---

### GET `/api/drivers/me/orders`

**Purpose:** Get driver's assigned orders.

**Authentication:** Required

**Authorization:** Driver only

**Query Parameters:**
- `status` (optional): Filter by status

**Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "pickupAddress": { ... },
      "totalPrice": 1500.00,
      "status": "assigned",
      "createdAt": "2024-01-01T12:00:00Z",
      "drops": [ ... ]
    }
  ],
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 15 seconds
- **Key:** `orders:driver:<driverId>:<status|all>`

---

### GET `/api/drivers/me/wallet`

**Purpose:** Get driver's wallet balance and transactions.

**Authentication:** Required

**Authorization:** Driver only

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "balance": 5000.00,
    "pendingBalance": 1000.00,
    "totalEarned": 15000.00,
    "transactions": [
      {
        "id": "uuid",
        "amount": 500.00,
        "type": "credit",
        "description": "Order delivery payment",
        "status": "completed",
        "createdAt": "2024-01-01T12:00:00Z"
      }
    ]
  },
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 30 seconds
- **Key:** `wallet:<driverId>`

---

### POST `/api/drivers/me/status`

**Purpose:** Update driver online/offline status.

**Authentication:** Required

**Authorization:** Driver only

**Request Body:**
```json
{
  "isOnline": true
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "You are now online",
  "data": {
    "isOnline": true
  }
}
```

**Note:** Currently logs status but doesn't persist to database (placeholder for future implementation).

---

### POST `/api/drivers/me/withdraw`

**Purpose:** Request withdrawal to M-Pesa.

**Authentication:** Required

**Authorization:** Driver only

**Request Body:**
```json
{
  "amount": 2000.00,
  "phoneNumber": "+254712345678"
}
```

**Validation:**
- `amount` must be > 0
- Driver must have sufficient balance

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Withdrawal request submitted",
  "data": {
    "id": "uuid",
    "driverId": "uuid",
    "amount": 2000.00,
    "phoneNumber": "+254712345678",
    "status": "pending",
    "createdAt": "2024-01-01T12:00:00Z"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Insufficient balance"
}
```

**How It Works:**
1. Validates amount > 0
2. Checks wallet balance
3. Creates withdrawal request (status: `pending`)
4. Admin must approve before processing
5. Invalidates wallet cache

**Cache Invalidation:**
- Invalidates `wallet` cache

---

## 4. Customer Endpoints

### GET `/api/customers`

**Purpose:** Get list of all customers (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "John Customer",
      "email": "customer@example.com",
      "phone": "+254712345678",
      "orderCount": 10,
      "totalSpent": 15000.00,
      "pendingOrders": 2,
      "status": "active",
      "createdAt": "2024-01-01T12:00:00Z"
    }
  ],
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 120 seconds (2 minutes)
- **Key:** `customers:list`

---

### GET `/api/customers/:customerId`

**Purpose:** Get customer details by ID (admin only).

**Authentication:** Required

**Authorization:** Admin only

**URL Parameters:**
- `customerId`: Customer UUID

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "customer@example.com",
    "phone": "+254712345678",
    "fullName": "John Customer",
    "createdAt": "2024-01-01T12:00:00Z",
    "recentOrders": [
      {
        "id": "uuid",
        "totalPrice": 1500.00,
        "status": "delivered",
        "createdAt": "2024-01-01T12:00:00Z"
      }
    ]
  },
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 300 seconds (5 minutes)
- **Key:** `customers:detail:<customerId>`

---

## 5. Dashboard Endpoints

### GET `/api/dashboard/stats`

**Purpose:** Get dashboard statistics (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "orders": {
      "total": 100,
      "today": 5,
      "pending": 10,
      "assigned": 5,
      "inTransit": 3,
      "delivered": 80,
      "cancelled": 2
    },
    "drivers": {
      "total": 20,
      "active": 15
    },
    "customers": {
      "total": 50
    },
    "revenue": {
      "total": 500000.00,
      "monthly": 50000.00
    },
    "pods": {
      "pending": 3
    }
  },
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 30 seconds
- **Key:** `dashboard:stats`
- **Optimization:** Uses aggregation queries and RPCs for performance

---

### GET `/api/dashboard/activity`

**Purpose:** Get recent activity feed (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Query Parameters:**
- `limit` (optional): Number of activities (default: 10)

**Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "type": "order",
      "description": "New order ORD12345 - pending",
      "amount": 1500.00,
      "customer": "John Customer",
      "timestamp": "2024-01-01T12:00:00Z"
    }
  ],
  "_meta": {
    "cached": false
  }
}
```

**Caching:**
- **TTL:** 15 seconds
- **Key:** `dashboard:activity:<limit>`

---

## 6. Admin Endpoints

### GET `/api/admin/cache/status`

**Purpose:** Get Redis cache connection status (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "connected": true,
    "message": "Redis cache is connected and operational"
  }
}
```

---

### POST `/api/admin/cache/clear`

**Purpose:** Clear all caches (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "All caches cleared successfully"
}
```

**How It Works:**
- Invalidates all cache entities:
  - `dashboard`
  - `orders`
  - `drivers`
  - `customers`
  - `user`
  - `wallet`

---

### POST `/api/admin/cache/clear/:entity`

**Purpose:** Clear specific cache entity (admin only).

**Authentication:** Required

**Authorization:** Admin only

**URL Parameters:**
- `entity`: Cache entity name (`dashboard`, `orders`, `drivers`, `customers`, `user`, `wallet`)

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Cache cleared for orders"
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Invalid entity. Valid options: dashboard, orders, drivers, customers, user, wallet"
}
```

---

### GET `/api/admin/health`

**Purpose:** Get system health information (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "server": "healthy",
    "cache": "connected",
    "timestamp": "2024-01-01T12:00:00Z",
    "uptime": 3600,
    "memory": {
      "rss": 50000000,
      "heapTotal": 30000000,
      "heapUsed": 20000000
    }
  }
}
```

---

## 7. POD (Proof of Delivery) Endpoints

### POST `/api/pods/upload`

**Purpose:** Upload proof of delivery (driver only).

**Authentication:** Required

**Authorization:** Driver only

**Status:** Placeholder (not yet implemented)

**Request Body:**
```json
{
  "orderId": "uuid",
  "image": "base64-encoded-image",
  "signature": "base64-encoded-signature",
  "notes": "Delivered successfully"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "POD upload endpoint - to be implemented"
}
```

---

### POST `/api/pods/:podId/approve`

**Purpose:** Approve or reject POD (admin only).

**Authentication:** Required

**Authorization:** Admin only

**Status:** Placeholder (not yet implemented)

**URL Parameters:**
- `podId`: POD UUID

**Request Body:**
```json
{
  "approved": true,
  "notes": "POD approved"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "POD approval endpoint - to be implemented"
}
```

---

## Routing Logic

### How Routes Are Organized

**File Structure:**
```
server/src/routes/
├── authRoutes.js      → /api/auth/*
├── orderRoutes.js     → /api/orders/*
├── driverRoutes.js    → /api/drivers/*
├── customerRoutes.js  → /api/customers/*
├── dashboardRoutes.js → /api/dashboard/*
├── adminRoutes.js     → /api/admin/*
└── podRoutes.js       → /api/pods/*
```

**Registration in `server.js`:**
```javascript
app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/pods', podRoutes);
```

### Middleware Chain

**Request Flow:**
```
1. Request arrives at Express
   │
2. CORS middleware (if needed)
   │
3. Body parser (JSON/URL-encoded)
   │
4. Rate limiter (if not health check)
   │
5. Route matching
   │
6. Route-specific middleware:
   │
   ├─ authenticate (extracts token, verifies, attaches user)
   │
   ├─ requireUserType(...) (checks user_type)
   │
   └─ validateCreateOrder (validates request body)
   │
7. Route handler (controller)
   │
8. Response sent
   │
9. Error handler (if error occurred)
```

### Authentication Middleware

**Location:** `server/src/middleware/auth.js`

**`authenticate` Middleware:**
```javascript
1. Extracts token from: req.headers.authorization
2. Removes "Bearer " prefix
3. Calls: supabase.auth.getUser(token)
4. Fetches user_type from: users table
5. Attaches to request: req.user = { id, email, user_type }
6. Calls next() or returns 401
```

**`requireUserType(...allowedTypes)` Middleware:**
```javascript
1. Checks: req.user.user_type in allowedTypes
2. If yes: calls next()
3. If no: returns 403 Forbidden
```

### Caching Strategy

**Cache-Aside Pattern:**
```javascript
1. Check cache for key
2. If found: return cached data
3. If not found:
   a. Fetch from database
   b. Store in cache with TTL
   c. Return data
```

**Cache Invalidation:**
- **On Create:** Invalidate list caches
- **On Update:** Invalidate detail + list caches
- **On Delete:** Invalidate list caches
- **Manual:** Admin can clear via `/api/admin/cache/clear`

**Cache Keys:**
- `orders:<userType>:<userId|all>:<status>:<limit>:<offset>`
- `orders:detail:<orderId>`
- `drivers:list`
- `customers:list`
- `dashboard:stats`
- `wallet:<driverId>`
- `user:<userId>:profile`

**Cache TTLs:**
- Dashboard stats: 30 seconds
- Orders list: 15 seconds
- Order detail: 60 seconds
- Drivers list: 60 seconds
- Customers list: 120 seconds
- User profile: 300 seconds
- Wallet: 30 seconds

---

## Error Handling

### HTTP Status Codes

- **200 OK:** Successful request
- **201 Created:** Resource created successfully
- **400 Bad Request:** Invalid request (validation error)
- **401 Unauthorized:** Missing or invalid authentication token
- **403 Forbidden:** Valid token but insufficient permissions
- **404 Not Found:** Resource not found
- **500 Internal Server Error:** Server error

### Error Response Format

**Standard Error:**
```json
{
  "success": false,
  "message": "Error description"
}
```

**Validation Error:**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "phone",
      "message": "Phone number is required"
    }
  ]
}
```

**Development Error (NODE_ENV=development):**
```json
{
  "success": false,
  "message": "Internal server error",
  "error": "Detailed error message",
  "stack": "Error stack trace"
}
```

---

## Rate Limiting

**Configuration:**
- **Window:** 15 minutes
- **Max Requests:** 100 (production), 1000 (development)
- **Scope:** Per IP address

**Exclusions:**
- `/health` endpoint (never rate limited)
- Localhost in development (excluded)

**Response (429 Too Many Requests):**
```json
{
  "success": false,
  "message": "Too many requests, please try again later"
}
```

---

## API Versioning

**Current Version:** v1 (implicit)

**Future:**
- Versioning via URL: `/api/v1/orders`
- Or via header: `Accept: application/vnd.logistics.v1+json`

---

## Testing Endpoints

### Using cURL

**Example: Get Orders**
```bash
curl -X GET http://localhost:3000/api/orders \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Example: Create Order**
```bash
curl -X POST http://localhost:3000/api/orders/create \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "pickupAddress": {
      "address": "123 Main St",
      "coordinates": { "lat": -1.2921, "lng": 36.8219 }
    },
    "drops": [{
      "recipientName": "Jane Doe",
      "address": "456 Oak Ave",
      "coordinates": { "lat": -1.3000, "lng": 36.8000 }
    }],
    "vehicleType": "small",
    "pricingMode": "distance_based"
  }'
```

### Using Postman

1. **Create Collection:** "Logistics Platform API"
2. **Set Base URL:** `http://localhost:3000/api`
3. **Set Authorization:** Bearer Token (use token from login)
4. **Create Requests:** One for each endpoint
5. **Test:** Run requests and verify responses

---

**End of README10.md**

**Next Section:** README11.md will cover Error Handling & Troubleshooting in detail.
