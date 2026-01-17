# Logistics Platform - Core Components: Admin Panel & Customer Panel

## Core Components (DEEP DIVE) - Frontend Applications

The Logistics Platform has two React-based web applications: the Admin Panel for platform administrators and the Customer Panel for end users. Both are built with React, Vite, and Tailwind CSS, and use Supabase for authentication. This section provides a comprehensive deep dive into both applications.

---

## Admin Panel

### Overview

The Admin Panel is a React application that provides administrators with complete control over the logistics platform. It allows admins to monitor operations, manage drivers and customers, assign orders, review proof of delivery, and view analytics.

**Technology Stack:**
- **Framework**: React 18 with Vite
- **Styling**: Tailwind CSS
- **Authentication**: Supabase Auth
- **Routing**: React Router v6
- **State Management**: React Context API
- **HTTP Client**: Native Fetch API
- **Notifications**: React Hot Toast

**Port**: 3002 (development)

### Directory Structure

```
client/admin-panel/
├── src/
│   ├── App.jsx                    # Main app component, route definitions
│   ├── main.jsx                   # React entry point
│   ├── index.css                  # Global styles
│   ├── components/                # Reusable UI components
│   │   ├── AdminLayout.jsx        # Main layout wrapper (sidebar + header)
│   │   ├── Sidebar.jsx            # Navigation sidebar
│   │   ├── Header.jsx              # Top header bar
│   │   ├── ProtectedRoute.jsx     # Route protection wrapper
│   │   └── ErrorBoundary.jsx      # Error handling component
│   ├── pages/                     # Page components
│   │   ├── Login.jsx              # Admin login page
│   │   ├── Dashboard.jsx          # Main dashboard with statistics
│   │   ├── OrdersList.jsx         # Orders management page
│   │   ├── OrderDetail.jsx        # Individual order details
│   │   ├── DriversList.jsx        # Drivers management page
│   │   └── CustomersList.jsx      # Customers list page
│   ├── contexts/                  # React Context providers
│   │   └── AuthContext.jsx        # Authentication state management
│   └── config/                    # Configuration files
│       └── api.js                 # API URL configuration
├── package.json
├── vite.config.js                # Vite build configuration
├── tailwind.config.js             # Tailwind CSS configuration
└── vercel.json                    # Vercel deployment configuration
```

### Main Entry Point: `App.jsx`

**File:** `client/admin-panel/src/App.jsx`

**Purpose:** Defines the application's routing structure and wraps the app with necessary providers.

**What It Does:**
1. **Route Definitions**: Sets up all application routes
2. **Protected Routes**: Wraps admin routes with authentication check
3. **Layout Wrapper**: Applies AdminLayout to all authenticated routes
4. **Error Handling**: Wraps app with ErrorBoundary for graceful error handling
5. **Toast Notifications**: Configures React Hot Toast for user notifications

**Key Code Structure:**

```jsx
<Routes>
  <Route path="/login" element={<Login />} />
  <Route
    path="/"
    element={
      <ProtectedRoute requireAdmin>
        <AdminLayout />
      </ProtectedRoute>
    }
  >
    <Route index element={<Navigate to="/dashboard" replace />} />
    <Route path="dashboard" element={<Dashboard />} />
    <Route path="orders" element={<OrdersList />} />
    <Route path="orders/:orderId" element={<OrderDetail />} />
    <Route path="drivers" element={<DriversList />} />
    <Route path="customers" element={<CustomersList />} />
  </Route>
</Routes>
```

**Why This Structure:**
- **Nested Routes**: All admin pages share the same layout (sidebar + header)
- **Protected Routes**: `ProtectedRoute` component checks authentication before rendering
- **requireAdmin Flag**: Ensures only admin users can access these routes

### Authentication Context: `contexts/AuthContext.jsx`

**Purpose:** Manages authentication state and provides authentication methods to all components.

**What It Does:**
1. **Session Management**: Checks for existing Supabase session on app load
2. **Auth State Listener**: Listens for auth state changes (login, logout)
3. **User Type Verification**: Fetches user_type from database to verify admin status
4. **Login Function**: Handles admin login with email/password
5. **Logout Function**: Clears session and redirects to login

**Key Features:**

**Session Persistence:**
- Uses Supabase's built-in session persistence (localStorage)
- Automatically restores session on page reload
- Verifies session validity on app initialization

**User Type Verification:**
- After login, fetches user_type from `users` table
- Verifies user is 'admin' type
- Blocks access if user is not admin

**Timeout Handling:**
- Includes 3-second timeout for auth initialization
- Prevents infinite loading if Supabase is unreachable
- Gracefully degrades if auth check fails

**Usage Example:**
```jsx
const { user, userType, loading, signIn, signOut } = useAuth();

if (loading) return <LoadingSpinner />;
if (!user || userType !== 'admin') return <Navigate to="/login" />;
```

### Protected Route Component: `components/ProtectedRoute.jsx`

**Purpose:** Wraps routes that require authentication and admin privileges.

**What It Does:**
1. **Checks Authentication**: Verifies user is logged in
2. **Checks User Type**: Verifies user is admin (if `requireAdmin` prop is true)
3. **Redirects**: Redirects to login if not authenticated
4. **Shows Loading**: Displays loading state during auth check

**Why Separate Component:**
- **Reusability**: Can be used for any protected route
- **Consistency**: Ensures all protected routes behave the same way
- **Clean Code**: Keeps route definitions clean and readable

### Layout Components

**AdminLayout.jsx:**
- Provides consistent layout for all admin pages
- Includes Sidebar and Header components
- Uses React Router's `<Outlet />` to render child routes

**Sidebar.jsx:**
- Navigation menu with links to all admin pages
- Highlights active route
- Collapsible for mobile responsiveness

**Header.jsx:**
- Displays user information
- Logout button
- Notifications (if implemented)

### Page Components

#### Dashboard: `pages/Dashboard.jsx`

**Purpose:** Displays real-time platform statistics and key metrics.

**What It Shows:**
- Total orders (with today's count)
- Active drivers (with total count)
- Pending PODs (awaiting approval)
- Total revenue (with monthly breakdown)
- Orders by status breakdown
- Quick stats (customers, today's orders, monthly revenue)

**How It Works:**
1. Fetches dashboard stats from `/api/dashboard/stats`
2. Displays data in card format with icons
3. Auto-refreshes periodically (or on manual refresh)
4. Shows loading state while fetching
5. Handles errors gracefully

**Key Features:**
- **Cached Data**: Backend caches stats for 30 seconds, ensuring fast responses
- **Currency Formatting**: Formats amounts in Kenyan Shillings (KES)
- **Visual Indicators**: Color-coded status badges and icons

#### Orders List: `pages/OrdersList.jsx`

**Purpose:** Displays all orders with filtering and detailed view.

**What It Shows:**
- Table of all orders with key information
- Status filter dropdown
- Expandable rows showing drop locations and order details
- Link to detailed order view

**Features:**
- **Status Filtering**: Filter by order status (pending, assigned, in_transit, delivered, cancelled)
- **Expandable Rows**: Click row to see drop locations and order details
- **Real-Time Updates**: Refresh button to fetch latest data
- **Date Formatting**: Displays dates in DD/MM/YYYY format
- **Currency Formatting**: Shows amounts in KES

**How It Works:**
1. Fetches orders from `/api/orders` (admin sees all orders)
2. Applies status filter if selected
3. Renders table with order data
4. Handles row expansion for detailed view
5. Navigates to order detail page on "View" click

#### Drivers List: `pages/DriversList.jsx`

**Purpose:** Manages driver accounts (create, read, update, delete).

**What It Shows:**
- Table of all drivers with key information
- Add Driver button (opens modal)
- Edit and Delete buttons for each driver
- Driver status badges (active, blocked, inactive)
- Wallet balance for each driver

**Features:**
- **CRUD Operations**: Full create, read, update, delete functionality
- **Add Driver Modal**: Form to create new driver accounts
- **Edit Driver Modal**: Form to update driver information
- **PIN Management**: Can update driver PIN
- **Status Management**: Can change driver status (active/blocked/inactive)

**How It Works:**
1. Fetches drivers from `/api/drivers`
2. Renders table with driver data
3. Opens modal for add/edit operations
4. Makes API calls to create/update/delete drivers
5. Refreshes list after operations

**Driver Creation Process:**
1. Admin fills form (name, phone, PIN, vehicle details)
2. Frontend validates input
3. POST request to `/api/drivers`
4. Backend creates Supabase Auth user, user record, driver record, and wallet
5. Success notification and list refresh

#### Customers List: `pages/CustomersList.jsx`

**Purpose:** Displays all customers with order statistics.

**What It Shows:**
- Table of all customers
- Order count per customer
- Total spent per customer
- Pending orders count
- Customer contact information

**Features:**
- **Customer Statistics**: Aggregated order data per customer
- **Read-Only View**: Admins can view but not edit customers (customers manage their own accounts)

### API Configuration: `config/api.js`

**Purpose:** Provides consistent API URL configuration for development and production.

**What It Does:**
- **Development**: Uses relative path `/api` (Vite proxy handles routing to localhost:3000)
- **Production**: Uses `VITE_API_URL` environment variable (full backend URL)

**Why This Design:**
- **Flexibility**: Easy to switch between local and production backends
- **No CORS Issues**: Relative paths in development avoid CORS problems
- **Environment-Specific**: Different URLs for different environments

**Usage:**
```jsx
import { getApiUrl } from '../config/api';

const response = await fetch(`${getApiUrl()}/orders`, {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

---

## Customer Panel

### Overview

The Customer Panel is a React application that allows customers to place delivery orders, track their orders in real-time, and view order history. It provides a simple, user-friendly interface for end users.

**Technology Stack:**
- **Framework**: React 18 with Vite
- **Styling**: Tailwind CSS
- **Authentication**: Supabase Auth
- **Routing**: React Router v6
- **State Management**: React Context API
- **HTTP Client**: Native Fetch API
- **Notifications**: React Hot Toast

**Port**: 3001 (development)

### Directory Structure

```
client/customer-panel/
├── src/
│   ├── App.jsx                    # Main app component, route definitions
│   ├── main.jsx                   # React entry point
│   ├── index.css                  # Global styles
│   ├── components/                # Reusable UI components
│   │   ├── Layout.jsx             # Main layout wrapper (header)
│   │   ├── Header.jsx             # Top header bar with navigation
│   │   ├── Breadcrumbs.jsx        # Breadcrumb navigation
│   │   ├── ProtectedRoute.jsx     # Route protection wrapper
│   │   └── ErrorBoundary.jsx      # Error handling component
│   ├── pages/                     # Page components
│   │   ├── Login.jsx              # Customer login page
│   │   ├── Signup.jsx             # Customer registration page
│   │   ├── PlaceOrder.jsx         # Order creation page
│   │   ├── OrdersList.jsx         # Customer's order history
│   │   └── OrderTracking.jsx      # Order tracking page with timeline
│   ├── contexts/                  # React Context providers
│   │   └── AuthContext.jsx        # Authentication state management
│   └── config/                    # Configuration files
│       └── api.js                 # API URL configuration
├── package.json
├── vite.config.js                # Vite build configuration
├── tailwind.config.js             # Tailwind CSS configuration
└── vercel.json                    # Vercel deployment configuration
```

### Main Entry Point: `App.jsx`

**Purpose:** Defines the application's routing structure for customer-facing pages.

**Route Structure:**
```jsx
<Routes>
  <Route path="/login" element={<Login />} />
  <Route path="/signup" element={<Signup />} />
  <Route
    path="/"
    element={
      <ProtectedRoute>
        <Layout />
      </ProtectedRoute>
    }
  >
    <Route index element={<PlaceOrder />} />
    <Route path="place-order" element={<PlaceOrder />} />
    <Route path="orders" element={<OrdersList />} />
    <Route path="orders/:orderId" element={<OrderTracking />} />
  </Route>
</Routes>
```

**Key Differences from Admin Panel:**
- **No Admin Check**: Only requires authentication, not admin role
- **Signup Route**: Customers can register themselves
- **Simpler Layout**: No sidebar, just header navigation
- **Customer-Focused Pages**: Place order, view orders, track orders

### Authentication Context: `contexts/AuthContext.jsx`

**Purpose:** Manages customer authentication state.

**Key Features:**
- **Signup Support**: Includes `signUp` function for customer registration
- **Email Confirmation**: Handles Supabase email confirmation flow
- **Simpler User Type Check**: Doesn't need to verify admin status
- **Redirect Configuration**: Configures email confirmation redirect URL

**Signup Process:**
1. Customer fills signup form (email, password, full name, phone)
2. Frontend calls `signUp` function
3. Supabase creates auth user and sends confirmation email
4. Customer clicks email link to confirm account
5. Customer is redirected to login page
6. Customer logs in with confirmed credentials

### Page Components

#### Place Order: `pages/PlaceOrder.jsx`

**Purpose:** Allows customers to create new delivery orders.

**What It Shows:**
- Map view (placeholder for Google Maps integration)
- Order form overlay with:
  - Pickup address input
  - Delivery address input (with "Add Destination" for multi-drop)
  - Vehicle type selection (small, medium, large)
  - Notes/Manifest/Schedule tabs
  - Place Order button

**Current State:**
- **Map Integration**: Placeholder (shows "Map integration coming soon")
- **Form**: Basic structure in place
- **API Integration**: TODO - needs to be connected to `/api/orders/create`

**Future Implementation:**
- Google Maps integration for address selection
- Real-time distance calculation
- Price preview before order placement
- Multi-drop support (up to 4 for retail, unlimited for corporate)

#### Orders List: `pages/OrdersList.jsx`

**Purpose:** Displays customer's order history.

**What It Shows:**
- Table of customer's orders
- Order status badges
- Expandable rows with order details and drop locations
- "Track" button to view detailed tracking
- Empty state with "Place New Order" button

**Features:**
- **Customer-Specific**: Only shows orders for logged-in customer
- **Status Indicators**: Color-coded status badges
- **Expandable Details**: Click row to see drop locations and order summary
- **Date Formatting**: DD/MM/YYYY format
- **Currency Formatting**: KES format

**How It Works:**
1. Fetches orders from `/api/orders/my/orders` (customer-specific endpoint)
2. Renders table with order data
3. Handles row expansion for detailed view
4. Navigates to tracking page on "Track" click

#### Order Tracking: `pages/OrderTracking.jsx`

**Purpose:** Shows detailed order information with timeline and map view.

**What It Shows:**
- **Left Panel:**
  - Order details card (order number, amount, status, date)
  - Pickup and delivery locations
  - Order timeline (pending → assigned → in_transit → delivered)
- **Right Panel:**
  - Map view (placeholder for Google Maps integration)
  - Map/Satellite toggle buttons

**Features:**
- **Timeline Visualization**: Shows order progress with checkmarks for completed steps
- **Status-Based Styling**: Completed steps are highlighted, pending steps are grayed out
- **Date Display**: Shows timestamps for each status change
- **Map Integration**: Placeholder for future Google Maps implementation

**Timeline Events:**
- Order Created (always shown)
- Order Assigned (shown if assigned_at exists)
- In Transit (shown if picked_up_at exists)
- Delivered (shown if delivered_at exists)

---

## Common Patterns and Architecture

### Authentication Flow

Both applications follow the same authentication pattern:

```
1. App Initialization
   ↓
2. AuthContext checks for existing Supabase session
   ↓
3. If session exists:
   - Fetches user_type from database
   - Sets user state
   - Allows access to protected routes
   ↓
4. If no session:
   - Redirects to login page
   ↓
5. User logs in
   ↓
6. Supabase Auth returns session
   ↓
7. AuthContext updates state
   ↓
8. User redirected to main app
```

### API Request Pattern

Both applications use the same pattern for API requests:

```jsx
const fetchData = async () => {
  try {
    // 1. Get JWT token from Supabase session
    const token = (await supabase.auth.getSession()).data.session?.access_token;
    
    // 2. Make API request with token
    const response = await fetch(`${getApiUrl()}/endpoint`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    // 3. Parse response
    const data = await response.json();
    
    // 4. Handle success/error
    if (data.success) {
      // Update state with data
    } else {
      // Show error message
    }
  } catch (error) {
    // Handle network errors
  }
};
```

### Error Handling

Both applications handle errors consistently:

1. **Network Errors**: Caught in try-catch, show user-friendly message
2. **API Errors**: Check `response.ok`, parse error message from response
3. **Validation Errors**: Show inline form errors
4. **Auth Errors**: Redirect to login if token invalid

### State Management

Both applications use React's built-in state management:

- **Local State**: `useState` for component-specific state
- **Context API**: `AuthContext` for global authentication state
- **No External Libraries**: No Redux, Zustand, or other state management libraries

**Why This Approach:**
- **Simplicity**: React Context is sufficient for authentication state
- **No Overhead**: Avoids unnecessary complexity
- **Easy to Understand**: Standard React patterns

### Styling Approach

Both applications use Tailwind CSS for styling:

- **Utility-First**: Classes like `bg-blue-600`, `text-white`, `rounded-lg`
- **Responsive Design**: Mobile-first approach with breakpoints
- **Consistent Design System**: Shared color palette and spacing
- **Component-Based**: Reusable styled components

### Environment Configuration

Both applications use Vite's environment variable system:

**Development:**
- `.env` file with `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
- API calls use relative paths (Vite proxy)

**Production:**
- Environment variables set in Vercel dashboard
- `VITE_API_URL` for backend API URL
- `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` for Supabase

---

## How Frontend and Backend Interact

### Request Flow Example: Admin Views Dashboard

```
1. Admin Panel (Browser)
   │
   │ Dashboard component mounts
   │ useEffect triggers fetchDashboardStats()
   │
   ▼
2. AuthContext
   │
   │ Gets JWT token from Supabase session
   │ Token stored in localStorage
   │
   ▼
3. API Request
   │
   │ GET /api/dashboard/stats
   │ Headers: Authorization: Bearer <token>
   │
   ▼
4. Express.js Server
   │
   │ authenticate middleware verifies token
   │ requireUserType('admin') checks user_type
   │ dashboardRoutes.js handles request
   │
   ▼
5. Cache Check
   │
   │ Checks Redis cache for dashboard stats
   │ If cache hit: returns cached data (30s TTL)
   │ If cache miss: queries database
   │
   ▼
6. Database Queries (if cache miss)
   │
   │ Parallel aggregation queries:
   │ - Count orders
   │ - Count orders by status
   │ - Count drivers
   │ - Sum revenue
   │
   ▼
7. Response
   │
   │ Returns JSON: { success: true, data: {...} }
   │ Stores in cache for 30 seconds
   │
   ▼
8. Admin Panel
   │
   │ Receives response
   │ Updates component state
   │ Renders dashboard cards
```

### Data Flow: Customer Places Order

```
1. Customer Panel
   │
   │ Customer fills order form
   │ Clicks "Place Order"
   │
   ▼
2. Form Validation
   │
   │ Client-side validation
   │ Checks required fields
   │
   ▼
3. API Request
   │
   │ POST /api/orders/create
   │ Body: { pickup_address, drops, vehicle_type, ... }
   │ Headers: Authorization: Bearer <token>
   │
   ▼
4. Express.js Server
   │
   │ authenticate middleware
   │ requireUserType('customer', 'admin')
   │ validateCreateOrder middleware
   │ orderController.createOrder
   │
   ▼
5. Order Service
   │
   │ Validates order data
   │ Calls pricingService.calculateOrderPrice
   │ Creates order in database
   │ Creates order_items
   │ Creates drops
   │
   ▼
6. Cache Invalidation
   │
   │ Invalidates orders cache
   │ Invalidates dashboard cache
   │
   ▼
7. Response
   │
   │ Returns: { success: true, data: { order_id, order_number, ... } }
   │
   ▼
8. Customer Panel
   │
   │ Shows success message
   │ Navigates to order tracking page
   │ Fetches order details
```

---

## Key Differences Between Admin and Customer Panels

| Feature | Admin Panel | Customer Panel |
|---------|------------|----------------|
| **User Type** | Admin only | Customer only |
| **Layout** | Sidebar + Header | Header only |
| **Pages** | Dashboard, Orders, Drivers, Customers | Place Order, Orders, Tracking |
| **Permissions** | Full CRUD on all entities | Read own orders, create orders |
| **Complexity** | More complex (management features) | Simpler (user-focused) |
| **Data Access** | All orders, all drivers, all customers | Own orders only |

---

**End of README3.md**

**Next Section:** README4.md will cover the Flutter Driver Mobile App in detail.
