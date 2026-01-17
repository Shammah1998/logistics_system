# Logistics Platform - User Flows & Workflows

## User Flows & Workflows

This section provides comprehensive, step-by-step workflows for each user type in the Logistics Platform. These flows are designed to be readable by non-technical stakeholders while providing enough detail for developers to understand the system behavior.

---

## Customer User Flow

### Overview

Customers use the Customer Panel (web application) to place delivery orders, track their orders in real-time, and view order history. The flow begins with account creation and ends with successful delivery confirmation.

### Complete Customer Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                    CUSTOMER JOURNEY                              │
└─────────────────────────────────────────────────────────────────┘

1. ACCOUNT CREATION
   │
   ├─ Customer visits Customer Panel (web app)
   ├─ Clicks "Sign Up"
   ├─ Fills registration form:
   │   • Email address
   │   • Password
   │   • Full name
   │   • Phone number
   ├─ Submits form
   ├─ Supabase Auth creates account
   ├─ Confirmation email sent
   ├─ Customer clicks email link
   ├─ Account confirmed
   └─ Redirected to login page
   
2. LOGIN
   │
   ├─ Customer enters email and password
   ├─ Clicks "Login"
   ├─ Supabase Auth validates credentials
   ├─ JWT token issued
   ├─ Token stored in browser localStorage
   ├─ Customer redirected to Place Order page
   └─ Ready to place orders
   
3. PLACE ORDER
   │
   ├─ Customer navigates to Place Order page
   ├─ Fills order form:
   │   • Pickup address (text input or map selection)
   │   • Delivery address(es) - can add multiple drops
   │   • Vehicle type (small, medium, large)
   │   • Pricing mode (distance_based or per_box)
   │   • Items (if per_box mode)
   │   • Delivery instructions (optional)
   │   • Payment method (M-Pesa, wallet, invoice)
   ├─ Clicks "Place Order"
   ├─ Frontend validates form data
   ├─ POST request to /api/orders/create
   │   • Includes JWT token in Authorization header
   │   • Sends order data in request body
   ├─ Backend processes order:
   │   • Validates customer authentication
   │   • Validates order data
   │   • Calculates price (distance or per-box)
   │   • Generates order number (ORD-YYYY-######)
   │   • Creates order record in database
   │   • Creates order_items records
   │   • Creates drops records
   │   • Invalidates cache
   ├─ Returns order confirmation
   ├─ Customer sees success message
   ├─ Order appears in "My Orders" list
   └─ Order status: "pending"
   
4. ORDER ASSIGNMENT (AUTOMATED BY ADMIN)
   │
   ├─ Admin views pending orders in Admin Panel
   ├─ Admin selects order
   ├─ Admin views available drivers
   ├─ Admin assigns driver to order
   ├─ Order status changes to "assigned"
   ├─ Driver receives notification (future feature)
   └─ Customer can see order is assigned (if they refresh)
   
5. ORDER TRACKING
   │
   ├─ Customer navigates to "My Orders" page
   ├─ Sees list of all their orders
   ├─ Clicks on order to view details
   ├─ Order Tracking page shows:
   │   • Order number and status
   │   • Pickup and delivery addresses
   │   • Timeline: pending → assigned → in_transit → delivered
   │   • Driver information (if assigned)
   │   • Map view (placeholder for future)
   ├─ Customer can refresh to see status updates
   └─ Real-time status updates (when driver updates status)
   
6. DELIVERY IN PROGRESS
   │
   ├─ Driver picks up order
   ├─ Driver updates status to "in_transit"
   ├─ Customer sees status change in tracking page
   ├─ Driver navigates to delivery location
   ├─ Driver delivers to recipient
   ├─ Driver captures POD (Proof of Delivery)
   └─ Order status remains "in_transit" until POD approved
   
7. DELIVERY COMPLETION
   │
   ├─ Driver uploads POD (photo + signature)
   ├─ POD status: "pending" (awaiting admin review)
   ├─ Admin reviews POD in Admin Panel
   ├─ Admin approves POD
   ├─ Order status changes to "delivered"
   ├─ Driver wallet credited with payment
   ├─ Customer receives delivery confirmation
   └─ Order appears in "Completed" section
   
8. ORDER HISTORY
   │
   ├─ Customer views "My Orders" page
   ├─ Sees all orders (pending, active, completed)
   ├─ Can filter by status
   ├─ Can view order details anytime
   └─ Can track completed orders for reference
```

### Customer Flow Diagram (Detailed)

```
                    ┌─────────────┐
                    │   START     │
                    │  (Visit     │
                    │   Website)  │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Has        │
                    │  Account?   │
                    └──┬──────┬───┘
                       │      │
                  NO   │      │   YES
                       │      │
                       ▼      ▼
            ┌─────────────┐  ┌─────────────┐
            │   Sign Up   │  │    Login    │
            │   Form      │  │   Form      │
            └──────┬──────┘  └──────┬──────┘
                   │                 │
                   ▼                 ▼
            ┌─────────────┐  ┌─────────────┐
            │  Email      │  │  Validate   │
            │  Confirm    │  │  Credentials│
            └──────┬──────┘  └──────┬──────┘
                   │                 │
                   └────────┬────────┘
                            │
                            ▼
                    ┌─────────────┐
                    │  Place      │
                    │  Order Page │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Fill Order │
                    │  Form       │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Validate   │
                    │  Form Data? │
                    └──┬──────┬───┘
                       │      │
                  NO   │      │   YES
                       │      │
                       ▼      ▼
            ┌─────────────┐  ┌─────────────┐
            │  Show      │  │  Submit to  │
            │  Errors    │  │  API        │
            └────────────┘  └──────┬──────┘
                                   │
                                   ▼
                            ┌─────────────┐
                            │  Calculate  │
                            │  Price      │
                            └──────┬──────┘
                                   │
                                   ▼
                            ┌─────────────┐
                            │  Create     │
                            │  Order      │
                            └──────┬──────┘
                                   │
                                   ▼
                            ┌─────────────┐
                            │  Order     │
                            │  Created   │
                            │  (pending) │
                            └──────┬──────┘
                                   │
                                   ▼
                    ┌───────────────────────────┐
                    │  Wait for Admin to        │
                    │  Assign Driver            │
                    └──────┬────────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Order      │
                    │  Assigned   │
                    │  (assigned) │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Track      │
                    │  Order      │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Driver     │
                    │  Picks Up   │
                    │  (in_transit)│
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Driver     │
                    │  Delivers   │
                    │  & Uploads │
                    │  POD        │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Admin      │
                    │  Approves   │
                    │  POD        │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Order      │
                    │  Delivered  │
                    │  (delivered)│
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │    END      │
                    │  (Complete) │
                    └─────────────┘
```

### Customer Decision Points

**1. Account Creation Decision:**
- **Has Account?** → YES: Go to Login
- **Has Account?** → NO: Go to Sign Up

**2. Order Validation Decision:**
- **Form Valid?** → YES: Submit to API
- **Form Valid?** → NO: Show validation errors

**3. Payment Method Decision:**
- **M-Pesa**: Requires payment before order creation
- **Wallet**: Deducts from customer wallet balance
- **Invoice**: Order created, payment due later

**4. Multi-Drop Decision:**
- **Retail Customer**: Maximum 4 drops
- **Corporate Customer**: Unlimited drops

---

## Driver User Flow

### Overview

Drivers use the Flutter mobile app to receive order assignments, manage deliveries, capture proof of delivery, and track earnings. The flow begins with login and continues through the delivery lifecycle.

### Complete Driver Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                      DRIVER JOURNEY                              │
└─────────────────────────────────────────────────────────────────┘

1. LOGIN
   │
   ├─ Driver opens mobile app
   ├─ Sees login screen
   ├─ Enters phone number (e.g., +254712345678)
   ├─ Enters PIN (4-6 digits)
   ├─ Taps "Login" button
   ├─ App sends POST /api/auth/drivers/login
   ├─ Backend validates:
   │   • Normalizes phone number to +254 format
   │   • Generates email: driver_<phone>@drivers.xobo.co.ke
   │   • Authenticates with Supabase Auth
   │   • Checks driver status (must be 'active')
   ├─ Returns JWT token + user data
   ├─ Token stored in SharedPreferences
   ├─ Auth state updated
   └─ Navigates to HomePage
   
2. HOME DASHBOARD
   │
   ├─ Driver sees dashboard with:
   │   • Personalized greeting
   │   • Today's summary (deliveries, earnings)
   │   • Recent orders preview
   │   • Online/Offline status toggle
   │   • Wallet balance
   ├─ Can toggle online/offline status
   ├─ Can view full orders list
   ├─ Can view earnings
   └─ Can view profile
   
3. VIEW ORDERS
   │
   ├─ Driver navigates to Orders tab
   ├─ Sees three tabs:
   │   • All Orders
   │   • Active Orders (pending, in_transit)
   │   • Completed Orders (delivered)
   ├─ Each order shows:
   │   • Order ID
   │   • Status badge
   │   • Pickup location
   │   • Drop count
   │   • Order amount
   ├─ Can tap order to see details
   └─ Can pull to refresh
   
4. ORDER ASSIGNMENT (BY ADMIN)
   │
   ├─ Admin assigns order to driver
   ├─ Order status: "assigned"
   ├─ Order appears in driver's "Active Orders" tab
   ├─ Driver can see order details:
   │   • Pickup address
   │   • All drop locations
   │   • Recipient names and phones
   │   • Delivery instructions
   │   • Order amount
   └─ Driver ready to accept order
   
5. ACCEPT ORDER (IMPLICIT)
   │
   ├─ Driver views assigned order
   ├─ Driver navigates to pickup location
   ├─ Driver arrives at pickup
   ├─ Driver picks up items
   ├─ Driver updates order status to "in_transit"
   │   (via API: PATCH /api/orders/:id/status)
   ├─ Order status changes
   └─ Customer can see order is in transit
   
6. DELIVERY PROCESS
   │
   ├─ Driver navigates to first drop location
   ├─ Driver arrives at drop location
   ├─ Driver contacts recipient (if needed)
   ├─ Driver delivers items
   ├─ Driver captures POD:
   │   • Takes photo of delivered items
   │   • Captures recipient signature
   │   • Enters recipient name and phone
   │   • Adds delivery notes (optional)
   ├─ Driver uploads POD
   │   (POST /api/pods/upload)
   ├─ POD status: "pending" (awaiting admin review)
   ├─ If multiple drops:
   │   • Driver repeats for each drop
   │   • Each drop has separate POD
   └─ Driver continues to next drop
   
7. POD APPROVAL (BY ADMIN)
   │
   ├─ Admin reviews POD in Admin Panel
   ├─ Admin verifies:
   │   • Photo shows delivered items
   │   • Signature is present
   │   • Recipient details match
   ├─ Admin decision:
   │   • APPROVE: Order marked delivered, driver paid
   │   • REJECT: POD rejected, driver must resubmit
   ├─ If approved:
   │   • Order status: "delivered"
   │   • Driver payment calculated:
   │     - Gross amount: Order total
   │     - Commission: 10% (platform fee)
   │     - Insurance: 2%
   │     - Withholding Tax: 5%
   │     - Net amount: Gross - deductions
   │   • Net amount credited to driver wallet
   │   • Transaction recorded
   │   • Wallet balance updated
   └─ Driver receives payment in wallet
   
8. EARNINGS MANAGEMENT
   │
   ├─ Driver navigates to Earnings tab
   ├─ Sees wallet information:
   │   • Available Balance (withdrawable)
   │   • Pending Balance (awaiting clearance)
   │   • Total Earned (lifetime)
   ├─ Views transaction history:
   │   • Credit transactions (earnings)
   │   • Debit transactions (withdrawals)
   │   • Transaction dates and descriptions
   ├─ Can request withdrawal:
   │   • Enters withdrawal amount
   │   • Enters M-Pesa phone number
   │   • Submits withdrawal request
   │   • Request status: "pending"
   └─ Waits for admin approval
   
9. WITHDRAWAL PROCESS
   │
   ├─ Driver requests withdrawal
   ├─ Admin reviews withdrawal request
   ├─ Admin verifies:
   │   • Driver has sufficient balance
   │   • M-Pesa number is valid
   ├─ Admin approves withdrawal
   ├─ Admin processes M-Pesa transfer (manual or automated)
   ├─ Withdrawal status: "processed"
   ├─ Amount deducted from driver wallet
   ├─ Transaction recorded
   └─ Driver receives funds in M-Pesa
```

### Driver Flow Diagram (Detailed)

```
                    ┌─────────────┐
                    │   START     │
                    │  (Open App) │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Has Valid  │
                    │  Session?   │
                    └──┬──────┬───┘
                       │      │
                  NO   │      │   YES
                       │      │
                       ▼      ▼
            ┌─────────────┐  ┌─────────────┐
            │   Login     │  │   Home      │
            │   Screen    │  │   Page      │
            └──────┬──────┘  └──────┬──────┘
                   │                 │
                   ▼                 │
            ┌─────────────┐          │
            │  Enter      │          │
            │  Phone+PIN  │          │
            └──────┬──────┘          │
                   │                 │
                   ▼                 │
            ┌─────────────┐          │
            │  Authenticate│          │
            │  with API    │          │
            └──────┬──────┘          │
                   │                 │
                   └────────┬────────┘
                            │
                            ▼
                    ┌─────────────┐
                    │  Home       │
                    │  Dashboard  │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Toggle     │
                    │  Online?    │
                    └──┬──────┬───┘
                       │      │
                  YES  │      │   NO
                       │      │
                       ▼      ▼
            ┌─────────────┐  ┌─────────────┐
            │  Status:    │  │  Status:   │
            │  Online     │  │  Offline   │
            └──────┬──────┘  └──────┬──────┘
                   │                 │
                   └────────┬────────┘
                            │
                            ▼
                    ┌─────────────┐
                    │  View       │
                    │  Orders     │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Has         │
                    │  Assigned    │
                    │  Orders?     │
                    └──┬──────┬───┘
                       │      │
                  YES  │      │   NO
                       │      │
                       ▼      ▼
            ┌─────────────┐  ┌─────────────┐
            │  View Order │  │  Wait for   │
            │  Details    │  │  Assignment │
            └──────┬──────┘  └─────────────┘
                   │
                   ▼
            ┌─────────────┐
            │  Navigate   │
            │  to Pickup  │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Pick Up    │
            │  Items      │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Update     │
            │  Status to  │
            │  in_transit│
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Navigate   │
            │  to Drop    │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Deliver    │
            │  to         │
            │  Recipient  │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Capture    │
            │  POD        │
            │  (Photo +   │
            │  Signature) │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Upload POD │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  More       │
            │  Drops?     │
            └──┬──────┬───┘
               │      │
          YES  │      │   NO
               │      │
               ▼      ▼
    ┌─────────────┐  ┌─────────────┐
    │  Repeat for │  │  Wait for  │
    │  Next Drop  │  │  Admin     │
    │             │  │  Approval  │
    └──────┬──────┘  └──────┬──────┘
           │                 │
           └────────┬────────┘
                    │
                    ▼
            ┌─────────────┐
            │  Admin      │
            │  Approves   │
            │  POD        │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Payment    │
            │  Credited   │
            │  to Wallet  │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  View       │
            │  Earnings   │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │  Request    │
            │  Withdrawal │
            │  (Optional) │
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │    END     │
            │  (Cycle    │
            │  Repeats)  │
            └─────────────┘
```

### Driver Decision Points

**1. Session Check Decision:**
- **Has Valid Session?** → YES: Go to Home
- **Has Valid Session?** → NO: Show Login

**2. Online Status Decision:**
- **Toggle Online?** → YES: Status = Online (available for orders)
- **Toggle Online?** → NO: Status = Offline (not available)

**3. Order Acceptance Decision:**
- **Accept Order?** → YES: Navigate to pickup, update status
- **Accept Order?** → NO: Order remains assigned (can accept later)

**4. POD Quality Decision:**
- **POD Approved?** → YES: Order delivered, payment credited
- **POD Rejected?** → NO: Must resubmit POD with corrections

**5. Withdrawal Decision:**
- **Request Withdrawal?** → YES: Submit request, wait for approval
- **Request Withdrawal?** → NO: Keep funds in wallet

---

## Admin User Flow

### Overview

Administrators use the Admin Panel (web application) to monitor operations, manage drivers and customers, assign orders, review proof of delivery, and process payments. The flow focuses on operational management and oversight.

### Complete Admin Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                      ADMIN JOURNEY                              │
└─────────────────────────────────────────────────────────────────┘

1. LOGIN
   │
   ├─ Admin visits Admin Panel (web app)
   ├─ Enters email and password
   ├─ Clicks "Login"
   ├─ Supabase Auth validates credentials
   ├─ Backend verifies user_type = 'admin'
   ├─ JWT token issued
   ├─ Token stored in browser localStorage
   └─ Redirected to Dashboard
   
2. DASHBOARD OVERVIEW
   │
   ├─ Admin sees dashboard with real-time statistics:
   │   • Total Orders (with today's count)
   │   • Active Drivers (with total count)
   │   • Pending PODs (awaiting review)
   │   • Total Revenue (with monthly breakdown)
   │   • Orders by Status breakdown
   │   • Quick stats (customers, today's orders)
   ├─ Data cached for 30 seconds (fast loading)
   ├─ Can refresh manually
   └─ Gets overview of platform health
   
3. ORDER MANAGEMENT
   │
   ├─ Admin navigates to "Orders" page
   ├─ Sees all orders in system (with filters)
   ├─ Can filter by status:
   │   • All Statuses
   │   • Pending
   │   • Assigned
   │   • In Transit
   │   • Delivered
   │   • Cancelled
   ├─ Can view order details:
   │   • Order number and status
   │   • Customer information
   │   • Pickup and drop locations
   │   • Driver assignment (if assigned)
   │   • Order amount
   │   • Timeline
   ├─ Can assign orders to drivers:
   │   • Selects unassigned order
   │   • Views available drivers
   │   • Selects driver
   │   • Assigns order
   │   • Order status: "assigned"
   └─ Can update order status if needed
   
4. DRIVER MANAGEMENT
   │
   ├─ Admin navigates to "Drivers" page
   ├─ Sees all drivers with:
   │   • Name and contact info
   │   • Status (active, blocked, inactive)
   │   • Vehicle type and registration
   │   • Wallet balance
   ├─ Can create new driver:
   │   • Clicks "Add Driver"
   │   • Fills form:
   │     - Full name
   │     - Phone number
   │     - PIN (4-6 digits)
   │     - Vehicle type
   │     - Vehicle registration
   │     - License number
   │   • Submits form
   │   • Backend creates:
   │     - Supabase Auth user
   │     - User record
   │     - Driver record
   │     - Wallet record
   │   • Driver can now log in
   ├─ Can edit driver:
   │   • Updates information
   │   • Can change PIN
   │   • Can change status
   └─ Can delete driver (removes account)
   
5. CUSTOMER MANAGEMENT
   │
   ├─ Admin navigates to "Customers" page
   ├─ Sees all customers with:
   │   • Name and contact info
   │   • Order count
   │   • Total spent
   │   • Pending orders count
   ├─ Can view customer details:
   │   • Full profile
   │   • Recent orders
   │   • Order history
   └─ Read-only view (customers manage own accounts)
   
6. POD REVIEW & APPROVAL
   │
   ├─ Admin navigates to Dashboard
   ├─ Sees "Pending PODs" count
   ├─ Clicks to view pending PODs (or navigates to Orders)
   ├─ Reviews POD details:
   │   • POD photo
   │   • Recipient signature
   │   • Recipient name and phone
   │   • Delivery notes
   │   • Order information
   ├─ Admin decision:
   │   • APPROVE:
   │     - POD status: "approved"
   │     - Order status: "delivered"
   │     - Calculate driver payment:
   │       * Gross: Order total
   │       * Commission: 10%
   │       * Insurance: 2%
   │       * Tax: 5%
   │       * Net: Gross - deductions
   │     - Credit driver wallet with net amount
   │     - Create transaction record
   │     - Update wallet balance
   │     - Customer sees delivery confirmation
   │   • REJECT:
   │     - POD status: "rejected"
   │     - Enter rejection reason
   │     - Driver must resubmit POD
   │     - Order remains in_transit
   └─ POD review complete
   
7. WITHDRAWAL PROCESSING
   │
   ├─ Driver requests withdrawal (via mobile app)
   ├─ Admin views withdrawal requests (future feature)
   ├─ Admin reviews request:
   │   • Verifies driver balance
   │   • Verifies M-Pesa number
   │   • Checks request amount
   ├─ Admin approves withdrawal
   ├─ Admin processes M-Pesa transfer (manual or automated)
   ├─ Updates withdrawal status: "processed"
   ├─ Amount deducted from driver wallet
   ├─ Transaction recorded
   └─ Driver receives funds
   
8. SYSTEM MANAGEMENT
   │
   ├─ Admin can view system health:
   │   • Server status
   │   • Cache status (Redis connection)
   │   • Uptime
   │   • Memory usage
   ├─ Admin can manage cache:
   │   • View cache status
   │   • Clear all caches
   │   • Clear specific cache entity
   └─ Admin can monitor system performance
```

### Admin Flow Diagram (Detailed)

```
                    ┌─────────────┐
                    │   START     │
                    │  (Login)    │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Validate  │
                    │  Admin      │
                    │  Credentials│
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Dashboard  │
                    │  Overview  │
                    └──────┬──────┘
                           │
                           ▼
            ┌───────────────────────────────┐
            │  What does Admin want to do?  │
            └───┬──────┬──────┬──────┬──────┘
                │      │      │      │
                ▼      ▼      ▼      ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
        │  Manage  │ │  Manage  │ │  Review  │ │  System  │
        │  Orders  │ │  Drivers │ │  PODs    │ │  Health  │
        └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
             │            │            │            │
             ▼            ▼            ▼            ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │  View Orders │ │  View        │ │  View        │ │  View        │
    │              │ │  Drivers     │ │  Pending     │ │  System      │
    │  Filter by   │ │              │ │  PODs        │ │  Status      │
    │  Status      │ │  Create/Edit │ │              │ │              │
    │              │ │  /Delete     │ │  Review POD  │ │  Manage      │
    │  Assign to   │ │  Drivers     │ │  Details     │ │  Cache       │
    │  Driver      │ │              │ │              │ │              │
    │              │ │  View Wallet │ │  Approve/     │ │  Clear Cache  │
    │  Update      │ │  Balances    │ │  Reject      │ │              │
    │  Status      │ └──────────────┘ └──────┬───────┘ └──────────────┘
    └──────┬───────┘                        │
           │                                 │
           │                                 ▼
           │                          ┌─────────────┐
           │                          │  POD        │
           │                          │  Approved?   │
           │                          └──┬──────┬───┘
           │                             │      │
           │                        YES  │      │   NO
           │                             │      │
           │                             ▼      ▼
           │                    ┌─────────────┐ ┌─────────────┐
           │                    │  Calculate  │ │  Reject POD │
           │                    │  Payment    │ │  (Enter     │
           │                    │             │ │  Reason)    │
           │                    └──────┬──────┘ └──────┬──────┘
           │                           │                │
           │                           ▼                │
           │                    ┌─────────────┐         │
           │                    │  Credit     │         │
           │                    │  Driver     │         │
           │                    │  Wallet     │         │
           │                    └──────┬──────┘         │
           │                           │                │
           └───────────────────────────┴────────────────┘
                                       │
                                       ▼
                                ┌─────────────┐
                                │  Continue   │
                                │  Managing  │
                                │  (Cycle    │
                                │  Repeats)  │
                                └─────────────┘
```

### Admin Decision Points

**1. POD Review Decision:**
- **POD Quality Good?** → YES: Approve, calculate payment, credit wallet
- **POD Quality Poor?** → NO: Reject, request resubmission

**2. Driver Assignment Decision:**
- **Assign Driver?** → YES: Select driver, assign order
- **Wait?** → NO: Leave order pending for later assignment

**3. Driver Status Decision:**
- **Driver Active?** → YES: Can assign orders
- **Driver Blocked/Inactive?** → NO: Cannot assign orders

**4. Withdrawal Approval Decision:**
- **Request Valid?** → YES: Approve, process payment
- **Request Invalid?** → NO: Reject, notify driver

---

## Cross-User Interactions

### Order Lifecycle (All Users)

```
CUSTOMER                    ADMIN                      DRIVER
   │                          │                          │
   │─── Place Order ─────────>│                          │
   │                          │                          │
   │                          │─── Assign to Driver ────>│
   │                          │                          │
   │<── Order Assigned ───────┼──────────────────────────│
   │                          │                          │
   │                          │<── Driver Picks Up ──────│
   │                          │                          │
   │<── In Transit ───────────┼──────────────────────────│
   │                          │                          │
   │                          │<── Driver Delivers ──────│
   │                          │     & Uploads POD        │
   │                          │                          │
   │                          │─── Review POD ───────────│
   │                          │                          │
   │                          │─── Approve POD ─────────>│
   │                          │     (Payment Credited)    │
   │                          │                          │
   │<── Delivered ────────────┼──────────────────────────│
   │                          │                          │
```

### Payment Flow (Driver & Admin)

```
DRIVER                       ADMIN
   │                          │
   │─── Complete Delivery ────>│
   │     (Upload POD)          │
   │                          │
   │                          │─── Review POD
   │                          │
   │                          │─── Approve POD
   │                          │     Calculate Payment:
   │                          │     - Gross: 1000 KES
   │                          │     - Commission: 100 KES (10%)
   │                          │     - Insurance: 20 KES (2%)
   │                          │     - Tax: 50 KES (5%)
   │                          │     - Net: 830 KES
   │                          │
   │<── Payment Credited ──────│
   │     (830 KES in wallet)   │
   │                          │
   │─── Request Withdrawal ───>│
   │     (Amount + M-Pesa #)   │
   │                          │
   │                          │─── Review Request
   │                          │
   │                          │─── Approve & Process
   │                          │     (M-Pesa Transfer)
   │                          │
   │<── Funds Received ────────│
   │     (In M-Pesa account)   │
```

---

## Status Lifecycle States

### Order Status Flow

```
pending
   │
   │ (Admin assigns driver)
   ▼
assigned
   │
   │ (Driver picks up)
   ▼
in_transit
   │
   │ (Driver delivers & uploads POD)
   │ (Admin approves POD)
   ▼
delivered
   
   OR
   
pending/assigned/in_transit
   │
   │ (Customer or Admin cancels)
   ▼
cancelled
```

### POD Status Flow

```
pending
   │
   │ (Driver uploads POD)
   │
   ├─── Admin Reviews ────┐
   │                       │
   │                       ▼
   │              ┌─────────────────┐
   │              │  Admin Decision  │
   │              └───┬─────────┬────┘
   │                  │         │
   │            APPROVE│         │REJECT
   │                  │         │
   ▼                  ▼         ▼
approved         (Payment    rejected
                  Credited)    │
                               │
                               │ (Driver resubmits)
                               │
                               └───> pending (cycle repeats)
```

### Withdrawal Status Flow

```
pending
   │
   │ (Driver requests withdrawal)
   │
   ├─── Admin Reviews ────┐
   │                       │
   │                       ▼
   │              ┌─────────────────┐
   │              │  Admin Decision  │
   │              └───┬─────────┬────┘
   │                  │         │
   │            APPROVE│         │REJECT
   │                  │         │
   ▼                  ▼         ▼
processed         (Funds      rejected
                  Sent)       │
                              │
                              │ (Driver can resubmit)
                              │
                              └───> pending (cycle repeats)
```

---

## Workflow Summary

### Customer Workflow Summary

**Primary Actions:**
1. Sign up / Login
2. Place order
3. Track order
4. View order history

**Time to Complete:** 5-10 minutes to place order, then passive tracking until delivery

**Key Interactions:**
- Customer → System: Order creation
- System → Customer: Status updates
- Customer → System: Order tracking requests

### Driver Workflow Summary

**Primary Actions:**
1. Login
2. View assigned orders
3. Accept and pick up order
4. Deliver and capture POD
5. View earnings
6. Request withdrawal

**Time to Complete:** Varies by delivery (30 minutes to several hours per order)

**Key Interactions:**
- Driver → System: Status updates, POD uploads
- System → Driver: Order assignments
- Driver → System: Withdrawal requests

### Admin Workflow Summary

**Primary Actions:**
1. Login
2. Monitor dashboard
3. Assign orders to drivers
4. Review and approve PODs
5. Manage drivers and customers
6. Process withdrawals

**Time to Complete:** Continuous monitoring, 2-5 minutes per order assignment, 1-2 minutes per POD review

**Key Interactions:**
- Admin → System: Order assignments, POD approvals, driver management
- System → Admin: Statistics, pending items, alerts

---

**End of README5.md**

**Next Section:** README6.md will cover Database Design & Data Flow in detail.
