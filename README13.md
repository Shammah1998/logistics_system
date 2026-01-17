# Logistics Platform - How to Extend or Modify the System

## How to Extend or Modify the System

This section provides step-by-step guides for extending and modifying the Logistics Platform. Whether you're adding new features, modifying existing functionality, or integrating with external services, this guide will help you do it safely and effectively.

---

## General Principles

### Before Making Changes

1. **Understand the Current System:**
   - Read relevant documentation (README1-12)
   - Review existing code
   - Understand data flow
   - Check database schema

2. **Plan Your Changes:**
   - Document what you're adding/modifying
   - Consider impact on existing features
   - Plan database migrations if needed
   - Consider caching implications

3. **Test Thoroughly:**
   - Test in development first
   - Test edge cases
   - Test with different user types
   - Verify cache invalidation

4. **Follow Existing Patterns:**
   - Use same code structure
   - Follow naming conventions
   - Use existing utilities
   - Maintain consistency

---

## Adding a New API Endpoint

### Step-by-Step Guide

**Example:** Add endpoint to get order statistics for a customer.

#### Step 1: Define the Route

**File:** `server/src/routes/orderRoutes.js`

```javascript
// Add new route
router.get('/stats', authenticate, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const userType = req.user.user_type;

    // Only customers can see their own stats
    if (userType !== 'customer') {
      return res.status(403).json({
        success: false,
        message: 'Only customers can view their order statistics'
      });
    }

    // Get statistics (implement logic)
    const stats = await getCustomerOrderStats(userId);

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
});
```

#### Step 2: Create Service Function (Optional)

**File:** `server/src/services/orderService.js`

```javascript
export async function getCustomerOrderStats(customerId) {
  const { data: orders, error } = await supabase
    .from('orders')
    .select('status, total_price, created_at')
    .eq('customer_id', customerId);

  if (error) throw error;

  // Calculate statistics
  const stats = {
    totalOrders: orders.length,
    totalSpent: orders.reduce((sum, o) => sum + (o.total_price || 0), 0),
    byStatus: {
      pending: orders.filter(o => o.status === 'pending').length,
      delivered: orders.filter(o => o.status === 'delivered').length,
      // ... more statuses
    }
  };

  return stats;
}
```

#### Step 3: Add Caching (If Needed)

**File:** `server/src/routes/orderRoutes.js`

```javascript
import { cache, CacheTTL, CacheKeys } from '../services/cacheService.js';

router.get('/stats', authenticate, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const cacheKey = cache.generateKey(CacheKeys.ORDERS, 'stats', userId);

    const { data: stats, fromCache } = await cache.getOrSet(
      cacheKey,
      () => getCustomerOrderStats(userId),
      CacheTTL.ORDERS_LIST // 15 seconds
    );

    res.json({
      success: true,
      data: stats,
      _meta: { cached: fromCache }
    });
  } catch (error) {
    next(error);
  }
});
```

#### Step 4: Add Cache Invalidation

**When orders change, invalidate stats cache:**

```javascript
// In order creation/update routes
await cache.del(cache.generateKey(CacheKeys.ORDERS, 'stats', customerId));
```

#### Step 5: Test the Endpoint

```bash
# Test with curl
curl -X GET http://localhost:3000/api/orders/stats \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

#### Step 6: Update Documentation

- Add endpoint to README10.md (API documentation)
- Update API documentation if separate file exists

---

## Adding a New Database Table

### Step-by-Step Guide

**Example:** Add `reviews` table for order reviews.

#### Step 1: Create Migration File

**File:** `server/database/migration_add_reviews.sql`

```sql
-- Create reviews table
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_reviews_order_id ON reviews(order_id);
CREATE INDEX idx_reviews_customer_id ON reviews(customer_id);
CREATE INDEX idx_reviews_driver_id ON reviews(driver_id);

-- Create updated_at trigger
CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Customers can view their own reviews
CREATE POLICY "Customers can view own reviews"
    ON reviews FOR SELECT
    USING (auth.uid() = customer_id);

-- Customers can create reviews for their orders
CREATE POLICY "Customers can create reviews"
    ON reviews FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- Admins can view all reviews
CREATE POLICY "Admins can view all reviews"
    ON reviews FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.user_type = 'admin'
        )
    );
```

#### Step 2: Run Migration

**In Supabase SQL Editor:**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Paste migration SQL
4. Run the query
5. Verify table created in Table Editor

#### Step 3: Update Schema File

**File:** `server/database/schema.sql`

Add the new table definition to the main schema file for reference.

#### Step 4: Create Repository/Service Functions

**File:** `server/src/services/reviewService.js`

```javascript
import { supabase } from '../server.js';

export async function createReview(orderId, customerId, rating, comment) {
  const { data, error } = await supabase
    .from('reviews')
    .insert({
      order_id: orderId,
      customer_id: customerId,
      rating,
      comment
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getOrderReviews(orderId) {
  const { data, error } = await supabase
    .from('reviews')
    .select(`
      *,
      users!customer_id (full_name, email)
    `)
    .eq('order_id', orderId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}
```

#### Step 5: Create API Routes

**File:** `server/src/routes/reviewRoutes.js`

```javascript
import express from 'express';
import { authenticate, requireUserType } from '../middleware/auth.js';
import { createReview, getOrderReviews } from '../services/reviewService.js';
import { cache, CacheTTL, CacheKeys } from '../services/cacheService.js';

const router = express.Router();
router.use(authenticate);

// Create review - customers only
router.post('/', requireUserType('customer'), async (req, res, next) => {
  try {
    const { orderId, rating, comment } = req.body;
    const customerId = req.user.id;

    // Validate
    if (!orderId || !rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Order ID and rating (1-5) are required'
      });
    }

    const review = await createReview(orderId, customerId, rating, comment);

    // Invalidate caches
    await cache.invalidateEntity(CacheKeys.ORDERS);

    res.status(201).json({
      success: true,
      data: review
    });
  } catch (error) {
    next(error);
  }
});

// Get reviews for order
router.get('/order/:orderId', async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const cacheKey = cache.generateKey('reviews', 'order', orderId);

    const { data: reviews, fromCache } = await cache.getOrSet(
      cacheKey,
      () => getOrderReviews(orderId),
      CacheTTL.ORDERS_LIST
    );

    res.json({
      success: true,
      data: reviews,
      _meta: { cached: fromCache }
    });
  } catch (error) {
    next(error);
  }
});

export default router;
```

#### Step 6: Register Route in Server

**File:** `server/src/server.js`

```javascript
import reviewRoutes from './routes/reviewRoutes.js';

// ... existing code ...

app.use('/api/reviews', reviewRoutes);
```

#### Step 7: Test

```bash
# Create review
curl -X POST http://localhost:3000/api/reviews \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "uuid",
    "rating": 5,
    "comment": "Great service!"
  }'

# Get reviews
curl -X GET http://localhost:3000/api/reviews/order/uuid \
  -H "Authorization: Bearer <token>"
```

---

## Adding a New Frontend Page

### Step-by-Step Guide (React)

**Example:** Add "Reviews" page to customer panel.

#### Step 1: Create Page Component

**File:** `client/customer-panel/src/pages/Reviews.jsx`

```javascript
import { useState, useEffect } from 'react';
import { apiCall } from '../config/api';
import { useAuth } from '../contexts/AuthContext';

export default function Reviews() {
  const { user } = useAuth();
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchReviews();
  }, []);

  const fetchReviews = async () => {
    try {
      const response = await apiCall('/reviews/my');
      setReviews(response.data);
    } catch (error) {
      console.error('Error fetching reviews:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">My Reviews</h1>
      <div className="space-y-4">
        {reviews.map(review => (
          <div key={review.id} className="border p-4 rounded">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-semibold">Order #{review.orderNumber}</p>
                <p className="text-gray-600">{review.comment}</p>
              </div>
              <div className="text-yellow-500">
                {'★'.repeat(review.rating)}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

#### Step 2: Add Route

**File:** `client/customer-panel/src/App.jsx`

```javascript
import Reviews from './pages/Reviews';

// ... existing code ...

<Routes>
  {/* ... existing routes ... */}
  <Route 
    path="/reviews" 
    element={
      <ProtectedRoute>
        <Reviews />
      </ProtectedRoute>
    } 
  />
</Routes>
```

#### Step 3: Add Navigation Link

**File:** `client/customer-panel/src/components/Header.jsx` (or wherever navigation is)

```javascript
<Link to="/reviews" className="nav-link">
  Reviews
</Link>
```

#### Step 4: Test

1. Start customer panel: `npm run dev`
2. Navigate to `/reviews`
3. Verify page loads and displays data

---

## Adding a New Mobile App Feature

### Step-by-Step Guide (Flutter)

**Example:** Add "Reviews" page to driver app.

#### Step 1: Create Page

**File:** `logistics_app/lib/presentation/pages/reviews/reviews_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

class ReviewsPage extends ConsumerStatefulWidget {
  const ReviewsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends ConsumerState<ReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      final response = await ApiService.get('/reviews/driver/me');
      setState(() {
        reviews = List<Map<String, dynamic>>.from(response['data']);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
      ),
      body: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Card(
            child: ListTile(
              title: Text('Order #${review['orderNumber']}'),
              subtitle: Text(review['comment'] ?? ''),
              trailing: Text('★' * (review['rating'] as int)),
            ),
          );
        },
      ),
    );
  }
}
```

#### Step 2: Add Route

**File:** `logistics_app/lib/presentation/routes/app_router.dart`

```dart
static const String reviews = '/reviews';
```

#### Step 3: Add Navigation

**File:** `logistics_app/lib/presentation/widgets/bottom_nav_bar.dart`

```dart
BottomNavigationBarItem(
  icon: Icon(Icons.star),
  label: 'Reviews',
),
```

#### Step 4: Test

```bash
flutter run
# Navigate to reviews page
```

---

## Modifying Existing Features

### Adding a Field to an Existing Table

**Example:** Add `delivery_notes` field to `orders` table.

#### Step 1: Create Migration

**File:** `server/database/migration_add_delivery_notes.sql`

```sql
-- Add column
ALTER TABLE orders 
ADD COLUMN delivery_notes TEXT;

-- Add comment
COMMENT ON COLUMN orders.delivery_notes IS 'Special delivery instructions';
```

#### Step 2: Update Schema File

**File:** `server/database/schema.sql`

Add the new column to the `orders` table definition.

#### Step 3: Update API

**File:** `server/src/routes/orderRoutes.js`

```javascript
// In order creation route
const { deliveryNotes, ...otherFields } = req.body;

const orderData = {
  ...otherFields,
  delivery_notes: deliveryNotes, // Add new field
  // ... other fields
};
```

#### Step 4: Update Frontend

**File:** `client/customer-panel/src/pages/PlaceOrder.jsx`

```javascript
const [deliveryNotes, setDeliveryNotes] = useState('');

// In form
<textarea
  value={deliveryNotes}
  onChange={(e) => setDeliveryNotes(e.target.value)}
  placeholder="Delivery notes"
/>

// In submit
await apiCall('/orders/create', {
  method: 'POST',
  body: JSON.stringify({
    ...orderData,
    deliveryNotes
  })
});
```

#### Step 5: Update Database Queries

Ensure all queries that select from `orders` include the new field (or use `*`).

---

## Adding Authentication for New User Type

### Step-by-Step Guide

**Example:** Add "manager" user type.

#### Step 1: Update Database ENUM

**File:** `server/database/migration_add_manager_type.sql`

```sql
-- Add new value to enum
ALTER TYPE user_type_enum ADD VALUE 'manager';
```

#### Step 2: Update Middleware

**File:** `server/src/middleware/auth.js`

```javascript
// requireUserType already supports multiple types
// Just use: requireUserType('admin', 'manager')
```

#### Step 3: Update RLS Policies

**File:** `server/database/rls_policies.sql`

```sql
-- Add manager policies
CREATE POLICY "Managers can view orders"
    ON orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.user_type IN ('admin', 'manager')
        )
    );
```

#### Step 4: Update Frontend

**File:** `client/admin-panel/src/contexts/AuthContext.jsx`

```javascript
// Update user type checks
const isAdmin = userType === 'admin' || userType === 'manager';
```

---

## Integrating External Services

### Step-by-Step Guide

**Example:** Integrate SMS notifications via Twilio.

#### Step 1: Install Package

```bash
cd server
npm install twilio
```

#### Step 2: Add Environment Variables

**File:** `.env`

```env
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890
```

#### Step 3: Create Service

**File:** `server/src/services/smsService.js`

```javascript
import twilio from 'twilio';

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

export async function sendSMS(to, message) {
  try {
    const result = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: to
    });
    return result;
  } catch (error) {
    console.error('SMS error:', error);
    throw error;
  }
}
```

#### Step 4: Use in Route

**File:** `server/src/routes/orderRoutes.js`

```javascript
import { sendSMS } from '../services/smsService.js';

// In order creation
router.post('/create', async (req, res, next) => {
  // ... create order ...
  
  // Send SMS notification
  try {
    await sendSMS(
      customer.phone,
      `Your order ${order.orderNumber} has been created!`
    );
  } catch (smsError) {
    // Log but don't fail order creation
    logger.warn('SMS notification failed', { error: smsError.message });
  }
  
  // ... return response ...
});
```

---

## Best Practices

### Code Organization

1. **Follow Existing Structure:**
   - Routes in `routes/`
   - Services in `services/`
   - Middleware in `middleware/`
   - Utils in `utils/`

2. **Naming Conventions:**
   - Files: `camelCase.js`
   - Components: `PascalCase.jsx`
   - Functions: `camelCase`
   - Constants: `UPPER_SNAKE_CASE`

3. **Error Handling:**
   - Always use try-catch
   - Pass errors to `next(error)`
   - Log errors appropriately
   - Return user-friendly messages

### Database Changes

1. **Always Use Migrations:**
   - Never modify `schema.sql` directly
   - Create migration files
   - Test migrations in development first

2. **Backup Before Changes:**
   - Export database before major changes
   - Test migrations on copy first

3. **Add Indexes:**
   - Add indexes for frequently queried columns
   - Consider composite indexes for multi-column queries

4. **Update RLS Policies:**
   - Always add RLS policies for new tables
   - Test policies with different user types

### Caching

1. **Cache Read Operations:**
   - Cache GET endpoints
   - Use appropriate TTLs
   - Invalidate on writes

2. **Cache Keys:**
   - Use consistent naming
   - Include relevant identifiers
   - Use `cache.generateKey()` helper

3. **Cache Invalidation:**
   - Invalidate on create/update/delete
   - Invalidate related entities
   - Consider cache warming for critical data

### Testing

1. **Test Locally First:**
   - Test in development environment
   - Test with different user types
   - Test edge cases

2. **Test API Endpoints:**
   - Use Postman/curl
   - Test with valid/invalid data
   - Test authentication/authorization

3. **Test Frontend:**
   - Test in browser
   - Test with different screen sizes
   - Test error states

### Documentation

1. **Update Documentation:**
   - Update relevant README files
   - Update API documentation
   - Add code comments for complex logic

2. **Document Breaking Changes:**
   - Note any breaking changes
   - Provide migration guides
   - Update version numbers

---

## Common Modification Scenarios

### Adding a New Order Status

1. **Update ENUM:**
   ```sql
   ALTER TYPE order_status_enum ADD VALUE 'on_hold';
   ```

2. **Update Frontend:**
   - Add status to status options
   - Update status display logic
   - Add status-specific actions

3. **Update Business Logic:**
   - Update status transition rules
   - Update pricing logic if needed
   - Update notifications

### Adding a New Payment Method

1. **Update ENUM:**
   ```sql
   ALTER TYPE payment_method_enum ADD VALUE 'card';
   ```

2. **Update API:**
   - Add payment method validation
   - Add payment processing logic
   - Update order creation

3. **Update Frontend:**
   - Add payment method option
   - Add payment form if needed
   - Update order summary

### Adding Real-time Updates

1. **Install Supabase Client:**
   ```bash
   npm install @supabase/supabase-js
   ```

2. **Subscribe to Changes:**
   ```javascript
   const subscription = supabase
     .channel('orders')
     .on('postgres_changes', {
       event: 'UPDATE',
       schema: 'public',
       table: 'orders',
       filter: `id=eq.${orderId}`
     }, (payload) => {
       // Handle update
     })
     .subscribe();
   ```

3. **Update UI:**
   - Update component state on changes
   - Show notifications
   - Refresh data

---

## Migration Checklist

When making significant changes:

- [ ] Plan changes and document
- [ ] Create database migration (if needed)
- [ ] Test migration in development
- [ ] Update API endpoints
- [ ] Update frontend components
- [ ] Update mobile app (if needed)
- [ ] Add/update tests
- [ ] Update documentation
- [ ] Test with different user types
- [ ] Test error cases
- [ ] Verify cache invalidation
- [ ] Check RLS policies
- [ ] Review security implications
- [ ] Deploy to staging
- [ ] Test in staging
- [ ] Deploy to production
- [ ] Monitor for issues

---

## Getting Help

### When Stuck

1. **Review Documentation:**
   - Check relevant README files
   - Review API documentation
   - Check code comments

2. **Check Existing Code:**
   - Find similar features
   - Review how they're implemented
   - Follow same patterns

3. **Test Incrementally:**
   - Make small changes
   - Test after each change
   - Isolate issues

4. **Ask for Help:**
   - Provide context
   - Show what you've tried
   - Include error messages

---

**End of README13.md**

**Next Section:** README14.md will cover the Glossary of Terms and final notes.
