# Logistics Platform - System Documentation

## PROJECT NAME

**Logistics Platform** is a comprehensive last-mile delivery management system designed to streamline the entire delivery lifecycle from order placement to driver payment. Similar to Sendy (Kenya), this platform serves three distinct user groups: customers who need items delivered, drivers who perform deliveries, and administrators who manage the entire operation. The system solves the problem of fragmented delivery management by providing a unified platform where customers can place orders with real-time tracking, drivers can manage their deliveries and earnings, and administrators can monitor operations, assign drivers, and approve payments—all in one integrated system.

---

## Table of Contents

This documentation is divided into multiple files for better organization:

- **README1.md** (This file) - Project Overview, System Architecture
- **README2.md** - Core Components: Server/Backend Deep Dive
- **README3.md** - Core Components: Admin Panel & Customer Panel
- **README4.md** - Core Components: Flutter Driver Mobile App
- **README5.md** - User Flows & Workflows
- **README6.md** - Database Design & Data Flow
- **README7.md** - File & Folder Structure
- **README8.md** - Security Model
- **README9.md** - Installation & Setup
- **README10.md** - Configuration Guide
- **README11.md** - API / Routing Logic
- **README12.md** - Error Handling & Troubleshooting
- **README13.md** - Design Decisions & Trade-offs
- **README14.md** - How to Extend or Modify the System
- **README15.md** - Glossary & Final Notes

---

## Overview

### What the System Does

The Logistics Platform is an end-to-end delivery management system that connects three types of users in a seamless workflow:

1. **Customers** place delivery orders through a web interface, specifying pickup and drop locations, vehicle requirements, and payment methods. They can track orders in real-time and view delivery history.

2. **Drivers** receive order assignments through a mobile app, navigate to pickup and delivery locations, capture proof of delivery (POD) with photos and signatures, and manage their earnings and withdrawal requests.

3. **Administrators** monitor the entire operation through a dashboard, assign orders to drivers, review and approve PODs, manage driver and customer accounts, and oversee financial transactions.

### Who Uses It

- **Retail Customers**: Individual users who need occasional deliveries (e.g., sending packages to friends, small business deliveries)
- **Corporate Customers**: Businesses with regular delivery needs who may have custom pricing agreements
- **Delivery Drivers**: Independent contractors who use the mobile app to accept and complete deliveries
- **Platform Administrators**: Operations staff who manage the platform, approve payments, and ensure smooth operations

### What Happens from First Interaction to Final Outcome

**Customer Journey:**
1. Customer signs up or logs in to the customer panel
2. Customer places an order by entering pickup and delivery addresses, selecting vehicle type, and choosing payment method
3. System calculates price based on distance or item count using the pricing engine
4. Order is created with status "pending" and appears in admin dashboard
5. Admin assigns order to an available driver
6. Driver receives notification and accepts the order
7. Customer can track order status in real-time (pending → assigned → in_transit → delivered)
8. Driver picks up items, navigates to delivery location, captures POD
9. Admin reviews and approves POD
10. Driver receives payment in their wallet (after deductions for commission, insurance, tax)
11. Customer receives delivery confirmation

**Driver Journey:**
1. Driver logs in to mobile app using phone number and PIN
2. Driver views available orders assigned to them
3. Driver accepts order and navigates to pickup location
4. Driver picks up items and updates order status to "in_transit"
5. Driver navigates to each drop location (for multi-drop orders)
6. Driver captures POD: photo of delivered items, recipient signature, recipient details
7. POD is uploaded and marked as "pending" for admin review
8. Upon admin approval, driver's wallet is credited with net earnings
9. Driver can view earnings, transaction history, and request withdrawals
10. Withdrawal requests are reviewed and processed by admin

**Admin Journey:**
1. Admin logs in to admin panel
2. Admin views dashboard with real-time statistics (orders, drivers, revenue, pending PODs)
3. Admin reviews pending orders and assigns them to available drivers
4. Admin monitors order progress and driver activity
5. Admin reviews pending PODs, verifies delivery completion, and approves/rejects
6. Upon POD approval, system automatically calculates driver payment and credits wallet
7. Admin reviews and processes driver withdrawal requests
8. Admin manages driver and customer accounts (create, update, block)
9. Admin views analytics and generates reports

### What Makes This System Necessary

Traditional delivery management relies on phone calls, spreadsheets, and manual coordination, leading to:
- **Inefficiency**: Manual order assignment and tracking
- **Lack of Transparency**: Customers can't track deliveries in real-time
- **Payment Delays**: Manual payment processing and reconciliation
- **Poor Driver Experience**: No centralized platform for managing deliveries and earnings
- **Limited Scalability**: Difficult to manage large numbers of orders and drivers

This system solves these problems by providing:
- **Automated Order Management**: System handles order creation, pricing, and assignment
- **Real-Time Tracking**: Customers see order status updates instantly
- **Automated Payments**: Driver payments calculated and processed automatically upon POD approval
- **Mobile-First Driver Experience**: Drivers have a dedicated app for all operations
- **Centralized Administration**: Admins have complete visibility and control through a single dashboard

---

## System Architecture

### High-Level Architecture

The system follows a three-tier architecture with clear separation between presentation, business logic, and data layers:

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
├──────────────────┬──────────────────┬──────────────────────────┤
│  Admin Panel     │  Customer Panel  │   Driver Mobile App      │
│  (React/Vite)    │  (React/Vite)    │   (Flutter)              │
│  Port: 3002      │  Port: 3001      │   (Mobile Device)        │
└────────┬─────────┴────────┬─────────┴──────────┬───────────────┘
         │                   │                    │
         │  HTTP/HTTPS      │  HTTP/HTTPS        │  HTTP/HTTPS
         │  JWT Tokens      │  JWT Tokens        │  JWT Tokens
         │                   │                    │
         └───────────────────┴────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API SERVER LAYER                           │
│                    (Express.js / Node.js)                       │
│                         Port: 3000                               │
├─────────────────────────────────────────────────────────────────┤
│  Middleware Stack:                                              │
│  • CORS (Cross-Origin Resource Sharing)                        │
│  • Helmet (Security Headers)                                    │
│  • Compression (Response Compression)                            │
│  • Rate Limiting (100 req/15min per IP)                         │
│  • Authentication (JWT Token Verification)                      │
│  • Error Handling (Centralized Error Handler)                   │
├─────────────────────────────────────────────────────────────────┤
│  Route Handlers:                                                │
│  • /api/auth/*      - Authentication & Authorization            │
│  • /api/orders/*   - Order Management                          │
│  • /api/drivers/*   - Driver Management                         │
│  • /api/customers/* - Customer Management                       │
│  • /api/dashboard/* - Statistics & Analytics                    │
│  • /api/pods/*     - Proof of Delivery                         │
│  • /api/admin/*    - Admin Operations & Cache Management        │
├─────────────────────────────────────────────────────────────────┤
│  Business Logic Layer:                                          │
│  • Services: orderService, pricingService, cacheService        │
│  • Controllers: orderController                                 │
│  • Repositories: orderRepository                               │
│  • Utils: logger, mapsService                                   │
└────────┬────────────────────────────────────────────────────────┘
         │
         │  Supabase Client (Service Role Key)
         │  Redis Client (Optional - for caching)
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA & CACHE LAYER                         │
├──────────────────────────┬──────────────────────────────────────┤
│   Supabase PostgreSQL    │   Redis Cache (Optional)             │
│   (Primary Database)      │   (Performance Optimization)         │
│                           │                                      │
│   • 14 Tables            │   • Dashboard Stats Cache           │
│   • Row Level Security   │   • Orders List Cache               │
│   • Triggers & Functions │   • Drivers List Cache              │
│   • Indexes              │   • Customers List Cache            │
│   • RLS Policies         │   • User Profile Cache              │
│                           │   • Wallet Balance Cache            │
└──────────────────────────┴──────────────────────────────────────┘
```

### Component Interaction Flow

#### How a Request Flows Through the System

**Example: Customer Places an Order**

```
1. Customer Panel (Browser)
   │
   │ User fills order form (pickup, drops, vehicle type, pricing mode)
   │ User clicks "Place Order"
   │
   ▼
2. React App (Frontend)
   │
   │ • Validates form data client-side
   │ • Gets JWT token from Supabase Auth (stored in localStorage)
   │ • Makes POST request to /api/orders/create
   │ • Includes Authorization: Bearer <token> header
   │
   ▼
3. Express.js Server (Backend)
   │
   │ Middleware Chain:
   │ • CORS checks origin (allows customer panel URL)
   │ • Helmet adds security headers
   │ • Compression compresses response
   │ • Rate Limiter checks request count (allows if under limit)
   │ • Authentication middleware:
   │   - Extracts token from Authorization header
   │   - Verifies token with Supabase Auth
   │   - Fetches user_type from users table
   │   - Attaches user object to req.user
   │ • requireUserType('customer', 'admin') checks user_type
   │ • validateCreateOrder validates request body
   │
   ▼
4. Order Controller
   │
   │ • Calls orderService.createOrder(orderData, customerId)
   │
   ▼
5. Order Service
   │
   │ • Validates order data
   │ • Calls pricingService.calculateOrderPrice()
   │   - Gets price card from database (company-specific or default)
   │   - If distance_based: calls mapsService.calculateDistance()
   │   - Calculates total price
   │ • Generates order number (ORD-YYYY-######)
   │ • Creates order record in database
   │ • Creates order_items records
   │ • Creates drops records
   │ • Returns complete order object
   │
   ▼
6. Supabase Database
   │
   │ • Inserts into orders table
   │ • Inserts into order_items table
   │ • Inserts into drops table
   │ • Triggers fire: update_updated_at, generate_order_number
   │ • RLS policies checked (service role bypasses RLS)
   │
   ▼
7. Cache Invalidation
   │
   │ • cache.invalidateEntity('orders') - clears all order caches
   │ • cache.invalidateEntity('dashboard') - clears dashboard stats cache
   │
   ▼
8. Response Back to Client
   │
   │ • Controller returns 201 Created with order data
   │ • Error handler catches any errors, formats error response
   │ • Response compressed and sent to client
   │
   ▼
9. Customer Panel (Browser)
   │
   │ • Receives success response
   │ • Shows success message
   │ • Navigates to order tracking page
   │ • Fetches order details (cached for 30 seconds)
```

**Example: Driver Logs In**

```
1. Flutter Mobile App
   │
   │ User enters phone number and PIN
   │ User taps "Login"
   │
   ▼
2. API Service (Flutter)
   │
   │ • Makes POST request to /api/auth/drivers/login
   │ • Sends { phone, password } in request body
   │
   ▼
3. Express.js Server
   │
   │ • authRoutes.js receives request
   │ • Normalizes phone number (+254 format)
   │ • Generates expected email: driver_<phone>@drivers.xobo.co.ke
   │
   ▼
4. Supabase Auth
   │
   │ • Attempts signInWithPassword(email, password)
   │ • Validates credentials
   │ • Returns JWT token and session
   │
   ▼
5. Backend Processing
   │
   │ • Fetches user record from users table
   │ • Creates user record if missing (auto-fix)
   │ • Fetches driver record from drivers table
   │ • Checks driver status (blocks if inactive/blocked)
   │ • Returns user data + token
   │
   ▼
6. Flutter App
   │
   │ • Stores token in SharedPreferences
   │ • Updates authProvider state
   │ • Navigates to HomePage
   │ • Fetches driver profile and orders
```

**Example: Admin Views Dashboard**

```
1. Admin Panel (Browser)
   │
   │ Admin navigates to /dashboard
   │ React component mounts
   │
   ▼
2. Dashboard Component
   │
   │ • Gets JWT token from Supabase session
   │ • Makes GET request to /api/dashboard/stats
   │ • Includes Authorization header
   │
   ▼
3. Express.js Server
   │
   │ • authenticate middleware verifies token
   │ • requireUserType('admin') checks user_type
   │ • dashboardRoutes.js handles request
   │
   ▼
4. Cache Check
   │
   │ • Generates cache key: logistics:dashboard:stats
   │ • Checks Redis cache (if available)
   │ • If cache hit: returns cached data (TTL: 30 seconds)
   │ • If cache miss: proceeds to fetch
   │
   ▼
5. Database Queries (if cache miss)
   │
   │ • Runs parallel aggregation queries:
   │   - Count total orders
   │   - Count orders by status (pending, assigned, in_transit, delivered, cancelled)
   │   - Count active drivers
   │   - Count total drivers
   │   - Count total customers
   │   - Sum total revenue (delivered orders)
   │   - Sum monthly revenue
   │   - Count pending PODs
   │   - Count today's orders
   │ • All queries run in parallel for performance
   │
   ▼
6. Cache Storage
   │
   │ • Stores result in Redis with 30-second TTL
   │ • Returns data to client
   │
   ▼
7. Admin Panel
   │
   │ • Receives dashboard stats
   │ • Renders cards and charts
   │ • Updates every 30 seconds (cache ensures fast responses)
```

### Where Decisions Are Made

**Authentication Decisions:**
- Made in `server/src/middleware/auth.js` - `authenticate` function
- Verifies JWT token with Supabase Auth
- Fetches user_type from database
- Attaches user object to request

**Authorization Decisions:**
- Made in `server/src/middleware/auth.js` - `requireUserType` function
- Checks if user's user_type is in allowed list
- Returns 403 Forbidden if not authorized

**Pricing Decisions:**
- Made in `server/src/services/pricingService.js`
- Selects price card (company-specific or default)
- Calculates price based on pricing_mode (distance_based or per_box)
- Applies minimum price if calculated price is too low

**Cache Decisions:**
- Made in `server/src/services/cacheService.js`
- Checks Redis cache before database queries
- Stores results with appropriate TTL
- Invalidates cache when data changes

**Order Status Transitions:**
- Made in route handlers (`server/src/routes/orderRoutes.js`)
- Validates status transitions (e.g., can't go from delivered to pending)
- Updates order status in database
- Invalidates related caches

### Where Data Is Stored and Retrieved

**Primary Data Storage:**
- **Supabase PostgreSQL Database**: All persistent data (users, orders, drivers, transactions, etc.)
- **Supabase Auth**: User authentication data (email, password hashes, sessions)
- **Supabase Storage**: File storage for POD images and signatures

**Temporary/Cache Storage:**
- **Redis Cache**: Frequently accessed data (dashboard stats, order lists, driver lists) with TTL
- **Browser localStorage**: JWT tokens for web apps (admin/customer panels)
- **Mobile SharedPreferences**: JWT tokens for Flutter app

**Data Retrieval Patterns:**
- **Direct Database Queries**: For write operations and cache misses
- **Cache-First Queries**: For read operations (check cache, fallback to database)
- **Parallel Queries**: For dashboard stats (multiple aggregations run simultaneously)

---

**End of README1.md**

**Next Section:** README2.md will cover the Server/Backend components in detail.
