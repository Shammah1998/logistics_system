# Logistics Platform - Database Design & Data Flow

## Database Design & Data Flow

The Logistics Platform uses Supabase PostgreSQL as its primary database. This section explains the database structure, relationships, data flow, and how data moves through the system from creation to final state.

---

## Database Overview

**Database Type:** PostgreSQL (via Supabase)  
**Schema:** `public` (default)  
**Authentication:** Supabase Auth (separate `auth` schema)  
**Row Level Security:** Enabled on all tables  
**Total Tables:** 14 main tables + Supabase Auth tables

**Key Features:**
- **UUID Primary Keys**: All tables use UUID for primary keys
- **Timestamps**: Automatic `created_at` and `updated_at` tracking
- **Foreign Keys**: Referential integrity enforced
- **Indexes**: Optimized for common query patterns
- **Triggers**: Automatic wallet creation, order number generation
- **RLS Policies**: Row-level security for data access control

---

## Entity Relationship Diagram (ASCII)

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE ERD                                 │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │ auth.users   │
                    │ (Supabase)   │
                    └──────┬───────┘
                           │
                           │ (1:1)
                           │
                    ┌──────▼───────┐
                    │   users      │◄──────────┐
                    │              │           │
                    │ id (PK, FK)  │           │
                    │ email        │           │
                    │ phone        │           │
                    │ user_type    │           │
                    │ company_id   │──┐        │
                    └──────┬───────┘  │        │
                           │          │        │
                    (1:1)  │          │        │
                           │          │        │
                    ┌──────▼───────┐  │        │
                    │   drivers    │  │        │
                    │              │  │        │
                    │ id (PK, FK)  │  │        │
                    │ company_id   │──┼──┐     │
                    │ license_num  │  │  │     │
                    │ vehicle_type │  │  │     │
                    │ status       │  │  │     │
                    └──────┬───────┘  │  │     │
                           │          │  │     │
                    (1:1)  │          │  │     │
                           │          │  │     │
                    ┌──────▼───────┐  │  │     │
                    │   wallets    │  │  │     │
                    │              │  │  │     │
                    │ id (PK)      │  │  │     │
                    │ driver_id    │──┘  │     │
                    │ balance      │     │     │
                    │ pending_bal  │     │     │
                    │ total_earned │     │     │
                    └──────┬───────┘     │     │
                           │             │     │
                    (1:N)  │             │     │
                           │             │     │
                    ┌──────▼───────┐     │     │
                    │ transactions  │     │     │
                    │               │     │     │
                    │ id (PK)       │     │     │
                    │ wallet_id (FK)│─────┘     │
                    │ order_id (FK) │           │
                    │ type          │           │
                    │ amount        │           │
                    │ status        │           │
                    └──────┬───────┘           │
                           │                   │
                    (1:N)  │                   │
                           │                   │
                    ┌──────▼──────────────┐     │
                    │ withdrawal_requests │     │
                    │                     │     │
                    │ id (PK)             │     │
                    │ driver_id (FK)      │─────┘
                    │ wallet_id (FK)      │
                    │ amount              │
                    │ mpesa_phone         │
                    │ status              │
                    └─────────────────────┘

                    ┌──────────────┐
                    │  companies   │
                    │              │
                    │ id (PK)      │◄──┐
                    │ name         │   │
                    │ client_type  │   │
                    │ reg_number   │   │
                    └──────┬───────┘   │
                           │           │
                    (1:N)  │           │
                           │           │
                    ┌──────▼───────┐   │
                    │   users      │───┘
                    │              │
                    │ company_id   │───┐
                    └──────┬───────┘   │
                           │           │
                    (1:N)  │           │
                           │           │
                    ┌──────▼───────┐   │
                    │   orders     │   │
                    │              │   │
                    │ id (PK)      │   │
                    │ order_number │   │
                    │ customer_id  │───┘
                    │ company_id   │───┐
                    │ driver_id    │───┼──┐
                    │ vehicle_type │   │  │
                    │ pricing_mode │   │  │
                    │ pickup_addr  │   │  │
                    │ total_price  │   │  │
                    │ status       │   │  │
                    │ payment_stat │   │  │
                    └──────┬───────┘   │  │
                           │           │  │
                    (1:N)  │           │  │
                           │           │  │
        ┌──────────────────┼───────────┼──┘
        │                  │           │
        │                  │           │
┌───────▼──────┐  ┌───────▼──────┐  │
│ order_items   │  │    drops     │  │
│               │  │              │  │
│ id (PK)       │  │ id (PK)      │  │
│ order_id (FK) │  │ order_id (FK)│──┘
│ description   │  │ sequence     │
│ quantity      │  │ recipient    │
│ unit_price    │  │ address      │
│ total_price   │  │ status       │
└───────────────┘  └──────┬───────┘
                          │
                    (1:N)  │
                          │
                    ┌──────▼───────┐
                    │     pods     │
                    │              │
                    │ id (PK)      │
                    │ order_id (FK)│
                    │ drop_id (FK) │
                    │ driver_id    │──┐
                    │ image_url    │  │
                    │ signature_url│  │
                    │ status       │  │
                    │ reviewed_by  │──┼──┐
                    └──────────────┘  │  │
                                      │  │
                    ┌─────────────────┘  │
                    │                     │
                    │                     │
            ┌───────▼──────────┐          │
            │   price_cards    │          │
            │                  │          │
            │ id (PK)          │          │
            │ company_id (FK)  │──────────┘
            │ vehicle_type     │
            │ pricing_mode     │
            │ base_price       │
            │ price_per_km     │
            │ price_per_box    │
            │ min_price        │
            │ is_active        │
            └──────────────────┘

                    ┌──────────────┐
                    │  audit_logs   │
                    │               │
                    │ id (PK)       │
                    │ user_id (FK)  │──┐
                    │ action        │  │
                    │ entity_type   │  │
                    │ entity_id     │  │
                    │ changes       │  │
                    └───────────────┘  │
                                       │
                    ┌──────────────────┘
                    │
                    │
            ┌───────▼──────────┐
            │ notifications    │
            │                  │
            │ id (PK)          │
            │ user_id (FK)     │──┐
            │ type             │  │
            │ title           │  │
            │ message         │  │
            │ read            │  │
            └──────────────────┘  │
                                  │
                                  │
                          ┌───────┘
                          │
                          │
                    ┌──────▼───────┐
                    │   users      │
                    │              │
                    │ (All users   │
                    │  reference   │
                    │  this table) │
                    └──────────────┘
```

---

## Table Descriptions

### Core User Tables

#### `users` Table

**Purpose:** Extends Supabase Auth users with application-specific data.

**Real-World Meaning:** Represents any person in the system (customer, driver, or admin).

**Key Fields:**
- `id` (UUID, PK, FK to `auth.users`): Unique identifier, matches Supabase Auth user ID
- `email` (TEXT): User's email address (must match Supabase Auth email)
- `phone` (TEXT): User's phone number (normalized to +254 format)
- `user_type` (ENUM): 'customer', 'admin', or 'driver' - determines system access
- `company_id` (UUID, FK): Links to `companies` table for corporate customers
- `created_at`, `updated_at` (TIMESTAMPTZ): Automatic timestamp tracking

**Relationships:**
- **1:1** with `auth.users` (Supabase Auth)
- **1:1** with `drivers` (if user_type = 'driver')
- **N:1** with `companies` (if user_type = 'customer' and has company)
- **1:N** with `orders` (as customer)
- **1:N** with `audit_logs` (user actions)
- **1:N** with `notifications` (user notifications)

**Why This Design:**
- **Separation of Concerns**: Supabase Auth handles authentication, this table handles application data
- **Single Source of Truth**: One table for all user types, differentiated by `user_type`
- **Company Support**: Corporate customers can be linked to companies for custom pricing

#### `companies` Table

**Purpose:** Represents corporate customers who may have custom pricing agreements.

**Real-World Meaning:** A business entity (e.g., "ABC Logistics Ltd") that places regular orders.

**Key Fields:**
- `id` (UUID, PK): Unique company identifier
- `name` (TEXT): Company name
- `registration_number` (TEXT, UNIQUE): Business registration number
- `client_type` (ENUM): 'retail' or 'corporate' - determines pricing and drop limits
- `kra_certificate_url` (TEXT): Link to tax certificate (for corporate customers)
- `billing_address` (JSONB): Structured billing address
- `contact_person` (TEXT): Primary contact name
- `contact_phone` (TEXT): Primary contact phone

**Relationships:**
- **1:N** with `users` (company employees/customers)
- **1:N** with `orders` (orders placed by company)
- **1:N** with `price_cards` (custom pricing for company)

**Why This Design:**
- **Corporate Pricing**: Companies can have custom price cards
- **Bulk Orders**: Corporate customers can place unlimited multi-drop orders
- **Billing**: Separate billing address for invoicing

#### `drivers` Table

**Purpose:** Stores driver-specific information and vehicle details.

**Real-World Meaning:** A delivery driver who performs deliveries for the platform.

**Key Fields:**
- `id` (UUID, PK, FK to `users.id`): Links to user account
- `company_id` (UUID, FK): Optional - driver can belong to a company
- `license_number` (TEXT): Driver's license number
- `vehicle_type` (ENUM): 'small', 'medium', 'large' - determines order eligibility
- `vehicle_registration` (TEXT): Vehicle registration number
- `status` (ENUM): 'active', 'blocked', 'inactive' - determines if driver can receive orders
- `blocked_reason` (TEXT): Reason for blocking (if status = 'blocked')

**Relationships:**
- **1:1** with `users` (driver's user account)
- **1:1** with `wallets` (driver's earnings wallet)
- **1:N** with `orders` (orders assigned to driver)
- **1:N** with `pods` (proof of delivery submissions)
- **1:N** with `withdrawal_requests` (withdrawal requests)

**Why This Design:**
- **Vehicle Matching**: Orders specify vehicle_type, drivers must match
- **Status Control**: Admins can block/inactivate drivers without deleting accounts
- **Company Drivers**: Drivers can belong to companies (future feature)

---

### Order Management Tables

#### `orders` Table

**Purpose:** Central table storing all delivery orders.

**Real-World Meaning:** A delivery request from a customer to deliver items from pickup to drop locations.

**Key Fields:**
- `id` (UUID, PK): Unique order identifier
- `order_number` (TEXT, UNIQUE): Human-readable order number (ORD-YYYY-######)
- `customer_id` (UUID, FK): Customer who placed the order
- `company_id` (UUID, FK): Company (if corporate customer)
- `driver_id` (UUID, FK): Assigned driver (null until assigned)
- `vehicle_type` (ENUM): Required vehicle size
- `pricing_mode` (ENUM): 'distance_based' or 'per_box' - how price was calculated
- `pickup_address` (JSONB): Structured pickup location with coordinates
- `total_distance_km` (NUMERIC): Total distance (if distance_based pricing)
- `base_price` (NUMERIC): Base price from price card
- `total_price` (NUMERIC): Final order price (after calculations)
- `status` (ENUM): 'pending', 'assigned', 'in_transit', 'delivered', 'cancelled'
- `payment_status` (ENUM): 'pending', 'paid', 'refunded'
- `payment_method` (ENUM): 'mpesa', 'wallet', 'invoice'
- `scheduled_pickup_time` (TIMESTAMPTZ): Optional scheduled pickup time

**Relationships:**
- **N:1** with `users` (customer)
- **N:1** with `companies` (if corporate order)
- **N:1** with `drivers` (assigned driver)
- **1:N** with `order_items` (items in order)
- **1:N** with `drops` (delivery locations)
- **1:N** with `pods` (proof of delivery records)
- **1:N** with `transactions` (payment transactions)

**Status Lifecycle:**
```
pending → assigned → in_transit → delivered
   │                                    │
   └────────────────────────────────────┘
              (cancelled)
```

**Why This Design:**
- **Flexible Pricing**: Supports both distance-based and per-box pricing
- **Multi-Drop Support**: One order can have multiple drops
- **Status Tracking**: Clear status progression for tracking
- **Payment Tracking**: Separate payment status from delivery status

#### `order_items` Table

**Purpose:** Stores individual items in an order (used for per-box pricing).

**Real-World Meaning:** A box or package being delivered (e.g., "2 boxes of electronics").

**Key Fields:**
- `id` (UUID, PK): Unique item identifier
- `order_id` (UUID, FK): Parent order
- `description` (TEXT): Item description
- `quantity` (INTEGER): Number of units
- `unit_price` (NUMERIC): Price per unit
- `total_price` (NUMERIC): quantity × unit_price

**Relationships:**
- **N:1** with `orders` (belongs to one order)

**Why This Design:**
- **Per-Box Pricing**: Required for per-box pricing mode
- **Itemization**: Customers can see what's being delivered
- **Price Calculation**: Enables accurate per-box pricing

#### `drops` Table

**Purpose:** Stores delivery destinations for orders (supports multi-drop orders).

**Real-World Meaning:** A location where items must be delivered (e.g., "John's house at 123 Main St").

**Key Fields:**
- `id` (UUID, PK): Unique drop identifier
- `order_id` (UUID, FK): Parent order
- `drop_sequence` (INTEGER): Order of delivery (1, 2, 3, ...)
- `recipient_name` (TEXT): Name of person receiving delivery
- `recipient_phone` (TEXT): Phone number of recipient
- `address` (JSONB): Structured address with coordinates
- `delivery_instructions` (TEXT): Special delivery instructions
- `status` (ENUM): 'pending', 'delivered', 'failed'
- `delivered_at` (TIMESTAMPTZ): Timestamp when delivered

**Relationships:**
- **N:1** with `orders` (belongs to one order)
- **1:N** with `pods` (proof of delivery for this drop)

**Constraints:**
- `UNIQUE (order_id, drop_sequence)`: Ensures sequence numbers are unique per order

**Why This Design:**
- **Multi-Drop Support**: One order can have multiple delivery locations
- **Sequence Tracking**: Ensures drops are delivered in correct order
- **Individual Status**: Each drop can have its own status
- **POD Linking**: Each drop can have its own POD

---

### Proof of Delivery Tables

#### `pods` Table (Proof of Delivery)

**Purpose:** Stores proof of delivery records submitted by drivers.

**Real-World Meaning:** Evidence that delivery was completed (photo, signature, recipient details).

**Key Fields:**
- `id` (UUID, PK): Unique POD identifier
- `order_id` (UUID, FK): Related order
- `drop_id` (UUID, FK): Specific drop (if multi-drop order)
- `driver_id` (UUID, FK): Driver who submitted POD
- `image_url` (TEXT): URL to POD photo (stored in Supabase Storage)
- `signature_url` (TEXT): URL to signature image (optional)
- `recipient_name` (TEXT): Name of person who received delivery
- `recipient_phone` (TEXT): Phone number of recipient
- `notes` (TEXT): Additional delivery notes
- `status` (ENUM): 'pending', 'approved', 'rejected'
- `reviewed_by` (UUID, FK): Admin who reviewed POD
- `reviewed_at` (TIMESTAMPTZ): When POD was reviewed
- `auto_approved_at` (TIMESTAMPTZ): If auto-approved (future feature)
- `rejection_reason` (TEXT): Reason for rejection (if rejected)

**Relationships:**
- **N:1** with `orders` (belongs to one order)
- **N:1** with `drops` (belongs to one drop, if specified)
- **N:1** with `drivers` (submitted by driver)
- **N:1** with `users` (reviewed by admin)

**Status Lifecycle:**
```
pending → approved (payment credited)
   │
   └──→ rejected (driver must resubmit)
```

**Why This Design:**
- **Delivery Verification**: Provides evidence of successful delivery
- **Multi-Drop Support**: Each drop can have separate POD
- **Review Process**: Admins can approve or reject PODs
- **Audit Trail**: Tracks who reviewed and when

---

### Financial Tables

#### `wallets` Table

**Purpose:** Stores driver earnings and wallet balances.

**Real-World Meaning:** Driver's account balance showing how much they've earned and can withdraw.

**Key Fields:**
- `id` (UUID, PK): Unique wallet identifier
- `driver_id` (UUID, FK, UNIQUE): One wallet per driver
- `balance` (NUMERIC): Available balance (can be withdrawn)
- `pending_balance` (NUMERIC): Balance awaiting clearance
- `total_earned` (NUMERIC): Lifetime total earnings
- `created_at`, `updated_at` (TIMESTAMPTZ): Timestamp tracking

**Relationships:**
- **1:1** with `drivers` (one wallet per driver)
- **1:N** with `transactions` (transaction history)
- **1:N** with `withdrawal_requests` (withdrawal requests)

**Why This Design:**
- **Balance Tracking**: Separates available, pending, and total earnings
- **Withdrawal Control**: Only `balance` can be withdrawn
- **Lifetime Tracking**: `total_earned` shows career earnings
- **Auto-Creation**: Trigger automatically creates wallet when driver is created

#### `transactions` Table

**Purpose:** Records all financial transactions (credits and debits) for driver wallets.

**Real-World Meaning:** A record of money being added to (credit) or removed from (debit) a driver's wallet.

**Key Fields:**
- `id` (UUID, PK): Unique transaction identifier
- `wallet_id` (UUID, FK): Driver's wallet
- `order_id` (UUID, FK): Related order (if payment from order)
- `type` (ENUM): 'credit' (earnings) or 'debit' (withdrawal)
- `amount` (NUMERIC): Transaction amount
- `description` (TEXT): Human-readable description
- `status` (ENUM): 'pending', 'completed', 'failed'
- `metadata` (JSONB): Additional transaction data
- `created_at` (TIMESTAMPTZ): Transaction timestamp

**Relationships:**
- **N:1** with `wallets` (belongs to wallet)
- **N:1** with `orders` (if payment from order)

**Transaction Types:**
- **Credit**: Earnings from completed deliveries
- **Debit**: Withdrawals to M-Pesa

**Why This Design:**
- **Audit Trail**: Complete history of all financial transactions
- **Transparency**: Drivers can see all credits and debits
- **Reconciliation**: Helps resolve payment disputes
- **Reporting**: Enables financial reporting and analytics

#### `withdrawal_requests` Table

**Purpose:** Tracks driver requests to withdraw funds to M-Pesa.

**Real-World Meaning:** A request from a driver to transfer money from their wallet to their M-Pesa account.

**Key Fields:**
- `id` (UUID, PK): Unique withdrawal request identifier
- `driver_id` (UUID, FK): Driver requesting withdrawal
- `wallet_id` (UUID, FK): Driver's wallet
- `amount` (NUMERIC): Withdrawal amount
- `mpesa_phone` (TEXT): M-Pesa phone number for transfer
- `status` (ENUM): 'pending', 'approved', 'rejected', 'processed'
- `approved_by` (UUID, FK): Admin who approved
- `processed_at` (TIMESTAMPTZ): When payment was processed
- `rejection_reason` (TEXT): Reason for rejection (if rejected)

**Relationships:**
- **N:1** with `drivers` (requested by driver)
- **N:1** with `wallets` (from wallet)
- **N:1** with `users` (approved by admin)

**Status Lifecycle:**
```
pending → approved → processed (funds sent)
   │
   └──→ rejected (request denied)
```

**Why This Design:**
- **Approval Workflow**: Admins must approve withdrawals
- **Audit Trail**: Tracks who approved and when
- **Status Tracking**: Clear status for driver visibility
- **Rejection Handling**: Can reject with reason

---

### Pricing Tables

#### `price_cards` Table

**Purpose:** Defines pricing rules for different vehicle types and pricing modes.

**Real-World Meaning:** A pricing configuration that determines how much an order costs (e.g., "Small vehicle, distance-based: 500 KES base + 50 KES/km").

**Key Fields:**
- `id` (UUID, PK): Unique price card identifier
- `company_id` (UUID, FK): Company (null for default pricing)
- `vehicle_type` (ENUM): 'small', 'medium', 'large'
- `pricing_mode` (ENUM): 'distance_based' or 'per_box'
- `base_price` (NUMERIC): Base price in KES
- `price_per_km` (NUMERIC): Price per kilometer (for distance_based)
- `price_per_box` (NUMERIC): Price per box (for per_box)
- `min_price` (NUMERIC): Minimum order price
- `is_active` (BOOLEAN): Whether this price card is currently active
- `valid_from` (TIMESTAMPTZ): When this pricing becomes effective
- `valid_to` (TIMESTAMPTZ): When this pricing expires (null = indefinite)

**Relationships:**
- **N:1** with `companies` (company-specific pricing, or null for default)

**Constraints:**
- `UNIQUE (company_id, vehicle_type, pricing_mode, valid_from)`: Prevents duplicate active price cards

**Why This Design:**
- **Flexible Pricing**: Supports both distance-based and per-box pricing
- **Company-Specific**: Corporate customers can have custom rates
- **Time-Based**: Can set pricing effective dates
- **Versioning**: Multiple price cards can exist (only active one used)

**Pricing Priority:**
1. Company-specific price card (if company_id matches)
2. Default price card (company_id is NULL)

---

### Supporting Tables

#### `audit_logs` Table

**Purpose:** Records all significant actions in the system for auditing and compliance.

**Real-World Meaning:** A log entry showing who did what, when, and what changed.

**Key Fields:**
- `id` (UUID, PK): Unique log entry identifier
- `user_id` (UUID, FK): User who performed action
- `action` (TEXT): Action performed (e.g., "order_created", "pod_approved")
- `entity_type` (TEXT): Type of entity affected (e.g., "order", "driver")
- `entity_id` (UUID): ID of affected entity
- `changes` (JSONB): What changed (before/after values)
- `ip_address` (TEXT): IP address of user
- `user_agent` (TEXT): Browser/app information
- `created_at` (TIMESTAMPTZ): When action occurred

**Why This Design:**
- **Compliance**: Required for financial and operational audits
- **Debugging**: Helps trace issues and user actions
- **Security**: Tracks suspicious activity
- **Analytics**: Can analyze user behavior patterns

#### `notifications` Table

**Purpose:** Stores in-app notifications for users.

**Real-World Meaning:** A message to a user (e.g., "Your order has been delivered").

**Key Fields:**
- `id` (UUID, PK): Unique notification identifier
- `user_id` (UUID, FK): User receiving notification
- `type` (TEXT): Notification type (e.g., "order_assigned", "payment_received")
- `title` (TEXT): Notification title
- `message` (TEXT): Notification message
- `data` (JSONB): Additional notification data
- `read` (BOOLEAN): Whether user has read notification
- `created_at` (TIMESTAMPTZ): When notification was created

**Why This Design:**
- **User Engagement**: Keeps users informed of important events
- **Read Tracking**: Can show unread notification count
- **Flexible Data**: JSONB allows different data structures per type

---

## Data Flow Through the System

### Order Creation Flow

```
1. Customer submits order form
   │
   ▼
2. Frontend validates form data
   │
   ▼
3. POST /api/orders/create
   │
   ▼
4. Backend validates authentication
   │
   ▼
5. Backend calculates price:
   │   • Gets price card (company-specific or default)
   │   • If distance_based: Calculates distance via Google Maps
   │   • If per_box: Sums item prices
   │   • Applies minimum price
   │
   ▼
6. Database operations (transaction):
   │   • INSERT INTO orders (order_number generated by function)
   │   • INSERT INTO order_items (for each item)
   │   • INSERT INTO drops (for each drop location)
   │
   ▼
7. Cache invalidation:
   │   • Clear orders cache
   │   • Clear dashboard cache
   │
   ▼
8. Return order confirmation to customer
```

### POD Approval and Payment Flow

```
1. Driver uploads POD
   │
   ▼
2. INSERT INTO pods (status = 'pending')
   │
   ▼
3. Admin reviews POD in Admin Panel
   │
   ▼
4. Admin approves POD
   │
   ▼
5. Backend calculates driver payment:
   │   • Gross: order.total_price
   │   • Commission: gross × 10%
   │   • Insurance: gross × 2%
   │   • Tax: gross × 5%
   │   • Net: gross - commission - insurance - tax
   │
   ▼
6. Database operations (transaction):
   │   • UPDATE pods SET status = 'approved', reviewed_by = admin_id
   │   • UPDATE orders SET status = 'delivered'
   │   • UPDATE wallets SET 
   │       balance = balance + net_amount,
   │       total_earned = total_earned + net_amount
   │   • INSERT INTO transactions (type = 'credit', amount = net_amount)
   │
   ▼
7. Cache invalidation:
   │   • Clear wallet cache
   │   • Clear orders cache
   │   • Clear dashboard cache
   │
   ▼
8. Driver sees payment in wallet
```

### Withdrawal Request Flow

```
1. Driver requests withdrawal
   │
   ▼
2. Frontend validates:
   │   • Amount > 0
   │   • Amount <= wallet.balance
   │   • Phone number provided
   │
   ▼
3. POST /api/drivers/me/withdraw
   │
   ▼
4. Backend validates:
   │   • Driver has sufficient balance
   │   • Amount is positive
   │
   ▼
5. INSERT INTO withdrawal_requests (status = 'pending')
   │
   ▼
6. Cache invalidation:
   │   • Clear wallet cache
   │
   ▼
7. Admin reviews request
   │
   ▼
8. Admin approves and processes M-Pesa transfer
   │
   ▼
9. Database operations (transaction):
   │   • UPDATE withdrawal_requests SET status = 'processed'
   │   • UPDATE wallets SET balance = balance - amount
   │   • INSERT INTO transactions (type = 'debit', amount = amount)
   │
   ▼
10. Driver receives funds in M-Pesa
```

---

## Status Values and Lifecycle States

### Order Status Enum

**Values:**
- `pending`: Order created, awaiting driver assignment
- `assigned`: Order assigned to driver, awaiting pickup
- `in_transit`: Driver has picked up, en route to delivery
- `delivered`: Delivery completed, POD approved
- `cancelled`: Order cancelled (by customer or admin)

**Valid Transitions:**
```
pending → assigned → in_transit → delivered
   │                                    │
   └────────────────────────────────────┘
              (cancelled)
```

**Who Can Change Status:**
- `pending → assigned`: Admin only
- `assigned → in_transit`: Driver only
- `in_transit → delivered`: Admin only (via POD approval)
- `any → cancelled`: Customer (if pending) or Admin

### POD Status Enum

**Values:**
- `pending`: POD uploaded, awaiting admin review
- `approved`: POD approved, payment credited
- `rejected`: POD rejected, driver must resubmit

**Valid Transitions:**
```
pending → approved (payment credited)
   │
   └──→ rejected → pending (resubmit)
```

**Who Can Change Status:**
- `pending → approved`: Admin only
- `pending → rejected`: Admin only

### Withdrawal Status Enum

**Values:**
- `pending`: Withdrawal requested, awaiting admin approval
- `approved`: Withdrawal approved, awaiting processing
- `rejected`: Withdrawal rejected
- `processed`: Payment processed, funds sent

**Valid Transitions:**
```
pending → approved → processed
   │
   └──→ rejected
```

**Who Can Change Status:**
- `pending → approved`: Admin only
- `approved → processed`: Admin only
- `pending → rejected`: Admin only

### Driver Status Enum

**Values:**
- `active`: Driver can receive orders
- `blocked`: Driver blocked (cannot receive orders)
- `inactive`: Driver account inactive

**Who Can Change Status:**
- Admin only (via driver management)

---

## Indexes and Performance

### Key Indexes

**Users Table:**
- `idx_users_email`: Fast email lookups
- `idx_users_phone`: Fast phone lookups
- `idx_users_user_type`: Filter by user type
- `idx_users_company_id`: Join with companies

**Orders Table:**
- `idx_orders_order_number`: Fast order number lookups
- `idx_orders_customer_id`: Customer's orders
- `idx_orders_driver_id`: Driver's orders
- `idx_orders_status`: Filter by status
- `idx_orders_created_at DESC`: Recent orders first

**Drops Table:**
- `idx_drops_order_id`: Order's drops
- `idx_drops_status`: Filter by drop status

**PODs Table:**
- `idx_pods_order_id`: Order's PODs
- `idx_pods_driver_id`: Driver's PODs
- `idx_pods_status`: Filter by POD status
- `idx_pods_created_at DESC`: Recent PODs first

**Transactions Table:**
- `idx_transactions_wallet_id`: Wallet's transactions
- `idx_transactions_order_id`: Order's transactions
- `idx_transactions_type`: Filter by credit/debit
- `idx_transactions_created_at DESC`: Recent transactions first

**Why These Indexes:**
- **Common Queries**: Indexes match most frequent query patterns
- **Join Performance**: Foreign key indexes speed up joins
- **Filtering**: Status and type indexes enable fast filtering
- **Sorting**: DESC indexes optimize "recent first" queries

---

## Database Functions and Triggers

### Automatic Functions

**`generate_order_number()`**
- **Purpose**: Generates unique order numbers (ORD-YYYY-######)
- **When Called**: Automatically when order is created
- **Format**: ORD-2024-000001, ORD-2024-000002, etc.
- **Why**: Human-readable order identifiers

**`create_driver_wallet()`**
- **Purpose**: Automatically creates wallet when driver is created
- **When Called**: Trigger fires after INSERT on drivers table
- **Why**: Ensures every driver has a wallet without manual creation

**`update_updated_at_column()`**
- **Purpose**: Automatically updates `updated_at` timestamp
- **When Called**: Trigger fires before UPDATE on multiple tables
- **Why**: Automatic timestamp tracking without manual updates

---

## Data Relationships Summary

### One-to-One Relationships

- `users` ↔ `drivers` (if user is driver)
- `drivers` ↔ `wallets` (one wallet per driver)
- `users` ↔ `auth.users` (Supabase Auth)

### One-to-Many Relationships

- `companies` → `users` (company employees)
- `companies` → `orders` (company orders)
- `companies` → `price_cards` (company pricing)
- `users` → `orders` (customer orders)
- `drivers` → `orders` (assigned orders)
- `drivers` → `pods` (submitted PODs)
- `drivers` → `withdrawal_requests` (withdrawal requests)
- `orders` → `order_items` (order items)
- `orders` → `drops` (delivery locations)
- `orders` → `pods` (proof of delivery)
- `wallets` → `transactions` (transaction history)
- `wallets` → `withdrawal_requests` (withdrawal requests)
- `users` → `audit_logs` (user actions)
- `users` → `notifications` (user notifications)

### Many-to-Many Relationships

- **None**: All relationships are one-to-one or one-to-many

---

## Data Integrity Rules

### Foreign Key Constraints

**CASCADE Deletes:**
- Deleting `auth.users` → Deletes `users` → Deletes `drivers` → Deletes `wallets`
- Deleting `orders` → Deletes `order_items`, `drops`, `pods`

**RESTRICT Deletes:**
- Cannot delete `orders` if referenced by `transactions`
- Cannot delete `drivers` if referenced by `pods`

**SET NULL:**
- Deleting `companies` → Sets `users.company_id` to NULL
- Deleting `orders` → Sets `transactions.order_id` to NULL

**Why These Rules:**
- **Data Integrity**: Prevents orphaned records
- **Business Logic**: Orders cannot be deleted if payments exist
- **Flexibility**: Companies can be removed without deleting users

---

## Row Level Security (RLS)

**Purpose:** Ensures users can only access data they're authorized to see.

**Key Policies:**

**Users:**
- Users can view/update their own profile
- Admins can view/update all users

**Orders:**
- Customers can view/update their own orders
- Drivers can view assigned orders
- Admins can view/update all orders

**Wallets:**
- Drivers can view their own wallet
- Admins can view all wallets

**PODs:**
- Drivers can view/submit PODs for assigned orders
- Customers can view PODs for their orders
- Admins can view/update all PODs

**Why RLS:**
- **Security**: Database-level access control
- **Multi-Tenancy**: Supports multiple companies securely
- **Compliance**: Meets data protection requirements

---

**End of README6.md**

**Next Section:** README7.md will cover File & Folder Structure in detail.
