# Logistics Platform - Error Handling & Troubleshooting

## Error Handling & Troubleshooting

This section provides comprehensive guidance on error handling, debugging techniques, and troubleshooting common issues in the Logistics Platform. It covers both server-side and client-side error scenarios.

---

## Error Handling Architecture

### Server-Side Error Handling

**Centralized Error Handler:** `server/src/middleware/errorHandler.js`

**Error Flow:**
```
1. Error occurs in route handler
   │
2. Error passed to next(error)
   │
3. Express error handler middleware catches it
   │
4. Error logged via Winston logger
   │
5. Error classified (validation, database, server)
   │
6. Appropriate HTTP status code determined
   │
7. Error response sent to client
```

**Error Classification:**
- **Validation Errors:** 400 Bad Request
- **Authentication Errors:** 401 Unauthorized
- **Authorization Errors:** 403 Forbidden
- **Not Found Errors:** 404 Not Found
- **Database Errors:** 500 Internal Server Error
- **Server Errors:** 500 Internal Server Error

### Client-Side Error Handling

**React Apps (Admin & Customer Panels):**
- Error boundaries catch component errors
- API errors displayed as toast notifications
- Network errors handled gracefully

**Flutter App:**
- Try-catch blocks around API calls
- Error messages displayed in UI
- Network errors show retry options

---

## Common Error Scenarios

### 1. Authentication Errors

#### Error: "Token required" (401)

**Symptoms:**
- API returns 401 Unauthorized
- User redirected to login page

**Causes:**
- Missing `Authorization` header
- Token expired
- Invalid token format

**Solutions:**

**Check Request Headers:**
```javascript
// Ensure Authorization header is included
headers: {
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
}
```

**Verify Token Validity:**
```javascript
// Check token expiration
const token = localStorage.getItem('token');
if (!token) {
  // Redirect to login
}
```

**Refresh Token:**
- Web apps: Supabase SDK handles automatic refresh
- Mobile app: Call `/api/auth/verify` to check token

**Debug Steps:**
1. Check browser DevTools → Network tab
2. Verify `Authorization` header is present
3. Check token in localStorage (web) or SharedPreferences (mobile)
4. Test token with `/api/auth/verify` endpoint

---

#### Error: "Invalid or expired token" (401)

**Symptoms:**
- Token exists but API rejects it
- User logged out unexpectedly

**Causes:**
- Token expired (JWT has expiration time)
- Token revoked
- Token tampered with

**Solutions:**

**Check Token Expiration:**
```javascript
// Decode JWT to check expiration
const token = localStorage.getItem('token');
const payload = JSON.parse(atob(token.split('.')[1]));
const expiration = payload.exp * 1000; // Convert to milliseconds
const now = Date.now();

if (now >= expiration) {
  // Token expired, redirect to login
}
```

**Handle Token Refresh:**
- Web apps: Supabase SDK automatically refreshes tokens
- Mobile app: Implement token refresh logic or re-login

**Re-authenticate:**
- If token is invalid, user must log in again

**Debug Steps:**
1. Decode JWT token (use jwt.io)
2. Check `exp` (expiration) claim
3. Verify token signature with Supabase
4. Check Supabase Auth dashboard for user status

---

#### Error: "Not allowed by CORS" (CORS Error)

**Symptoms:**
- Browser console shows CORS error
- Request fails before reaching server

**Causes:**
- Frontend URL not in allowed origins
- Missing CORS headers
- Preflight request failing

**Solutions:**

**Check CORS Configuration:**
```javascript
// server/src/server.js
const allowedOrigins = [
  'http://localhost:3001',  // Customer panel
  'http://localhost:3002',  // Admin panel
  process.env.CUSTOMER_PANEL_URL,
  process.env.ADMIN_PANEL_URL
];
```

**Verify Environment Variables:**
- Check `ADMIN_PANEL_URL` and `CUSTOMER_PANEL_URL` in `.env`
- Ensure production URLs are included

**Development Fix:**
- Server allows all localhost origins in development
- Check if you're using correct port (3001 for customer, 3002 for admin)

**Debug Steps:**
1. Check browser console for CORS error details
2. Verify request origin matches allowed origins
3. Check server logs for CORS blocking
4. Test with Postman (bypasses CORS)

---

### 2. Database Errors

#### Error: "relation 'orders' does not exist" (500)

**Symptoms:**
- API returns 500 Internal Server Error
- Server logs show table not found

**Causes:**
- Database schema not initialized
- Table name typo
- Database connection issue

**Solutions:**

**Initialize Database Schema:**
```sql
-- Run in Supabase SQL Editor
-- Execute server/database/schema.sql
```

**Verify Tables Exist:**
```sql
-- Check tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

**Check Database Connection:**
- Verify `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in `.env`
- Test connection in Supabase dashboard

**Debug Steps:**
1. Check Supabase dashboard → Table Editor
2. Verify all 14 tables exist
3. Check server logs for connection errors
4. Test Supabase connection with simple query

---

#### Error: "Row Level Security policy violation" (403)

**Symptoms:**
- Database query fails with RLS error
- Data not accessible even with valid token

**Causes:**
- RLS policies too restrictive
- User doesn't have permission
- Service role key not used (backend should use it)

**Solutions:**

**Check RLS Policies:**
```sql
-- View RLS policies
SELECT * FROM pg_policies WHERE tablename = 'orders';
```

**Verify Service Role Key:**
- Backend must use `SUPABASE_SERVICE_ROLE_KEY` (bypasses RLS)
- Never use service role key in frontend

**Check User Permissions:**
- Verify user_type in `users` table
- Ensure RLS policies allow access

**Debug Steps:**
1. Check RLS policies in Supabase dashboard
2. Verify user_type matches policy requirements
3. Test query with service role key (backend only)
4. Check server logs for RLS errors

---

#### Error: "Foreign key constraint violation" (500)

**Symptoms:**
- Insert/update fails
- Error mentions foreign key

**Causes:**
- Referenced record doesn't exist
- Invalid UUID format
- Cascade delete issue

**Solutions:**

**Verify Referenced Records:**
```sql
-- Check if referenced record exists
SELECT * FROM users WHERE id = 'referenced-uuid';
```

**Check UUID Format:**
- Ensure UUIDs are valid format
- Use `uuid()` function for new IDs

**Handle Cascades:**
- Check ON DELETE CASCADE in foreign keys
- Ensure parent records exist before creating children

**Debug Steps:**
1. Check error message for which foreign key failed
2. Verify referenced record exists
3. Check UUID format
4. Review database schema for cascade rules

---

### 3. Validation Errors

#### Error: "Validation failed" (400)

**Symptoms:**
- API returns 400 Bad Request
- Error includes field-specific messages

**Causes:**
- Missing required fields
- Invalid data format
- Value out of range

**Solutions:**

**Check Request Body:**
```javascript
// Ensure all required fields are present
{
  "pickupAddress": { ... },  // Required
  "drops": [ ... ],          // Required (at least 1)
  "vehicleType": "small",    // Required, must be: small, medium, large
  "pricingMode": "distance_based"  // Required, must be: distance_based, per_box
}
```

**Validate Data Types:**
- Numbers must be numbers (not strings)
- Dates must be ISO format
- Coordinates must be objects with lat/lng

**Check Field Constraints:**
- Phone numbers: Must match format
- PINs: Must be 4-6 digits
- Amounts: Must be positive numbers

**Debug Steps:**
1. Check error response for specific field errors
2. Verify request body matches API documentation
3. Test with Postman to isolate frontend issues
4. Check server logs for validation details

---

### 4. Network Errors

#### Error: "Network request failed" (Client)

**Symptoms:**
- Request fails immediately
- No response from server

**Causes:**
- Server not running
- Wrong API URL
- Network connectivity issue
- Firewall blocking request

**Solutions:**

**Check Server Status:**
```bash
# Verify server is running
curl http://localhost:3000/health
```

**Verify API URL:**
```javascript
// Development
const API_URL = 'http://localhost:3000/api';

// Production
const API_URL = 'https://your-backend.onrender.com/api';
```

**Check Network:**
- Verify internet connection
- Check firewall settings
- Test with Postman (bypasses browser issues)

**Mobile App Specific:**
- Use device IP instead of `localhost`
- Update `API_BASE_URL` in `.env` or build config

**Debug Steps:**
1. Check server logs for incoming requests
2. Test API with Postman/curl
3. Verify API URL in client code
4. Check network tab in browser DevTools

---

#### Error: "Connection timeout" (Client)

**Symptoms:**
- Request hangs then times out
- No response received

**Causes:**
- Server overloaded
- Database query taking too long
- Network latency
- Rate limiting

**Solutions:**

**Check Server Performance:**
- Monitor server CPU/memory usage
- Check database query performance
- Review slow query logs

**Optimize Queries:**
- Add database indexes
- Use pagination for large datasets
- Implement caching

**Increase Timeout:**
```javascript
// Client-side timeout
fetch(url, {
  signal: AbortSignal.timeout(30000) // 30 seconds
});
```

**Debug Steps:**
1. Check server logs for slow queries
2. Monitor database performance
3. Test with smaller datasets
4. Check rate limiting status

---

### 5. Cache Errors

#### Error: "Redis connection failed" (Server)

**Symptoms:**
- Server logs show Redis errors
- Warning: "Running without cache"

**Causes:**
- Redis not running
- Wrong Redis URL
- Network issue

**Solutions:**

**Check Redis Status:**
```bash
# Test Redis connection
redis-cli ping
# Should return: PONG
```

**Verify Redis URL:**
```env
# .env file
REDIS_URL=redis://localhost:6379
```

**Start Redis:**
```bash
# Local development
redis-server

# Or with Docker
docker run -p 6379:6379 redis
```

**Note:** Server works without Redis (just slower, no caching)

**Debug Steps:**
1. Check Redis is running
2. Verify `REDIS_URL` in `.env`
3. Test connection: `redis-cli ping`
4. Check server logs for Redis errors

---

### 6. File Upload Errors

#### Error: "File too large" (413)

**Symptoms:**
- POD upload fails
- Error mentions file size

**Causes:**
- File exceeds size limit
- Server body size limit

**Solutions:**

**Check File Size:**
- Limit file size to 5MB (recommended)
- Compress images before upload

**Increase Server Limit:**
```javascript
// server/src/server.js
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
```

**Client-Side Validation:**
```javascript
if (file.size > 5 * 1024 * 1024) {
  // File too large
}
```

**Debug Steps:**
1. Check file size before upload
2. Verify server body size limits
3. Test with smaller file
4. Check server logs for size errors

---

## Debugging Techniques

### Server-Side Debugging

#### 1. Enable Detailed Logging

**Development Mode:**
```javascript
// server/src/utils/logger.js
// Winston logger automatically logs more details in development
```

**Check Log Files:**
```bash
# Development logs
tail -f server/logs/combined.log
tail -f server/logs/error.log
```

**Production Logs:**
- Render: Check logs in dashboard
- Other platforms: Check platform-specific logging

---

#### 2. Add Debug Logging

**Add Logging to Routes:**
```javascript
import { logger } from '../utils/logger.js';

router.post('/endpoint', async (req, res, next) => {
  logger.info('Request received', {
    body: req.body,
    userId: req.user?.id,
    userType: req.user?.user_type
  });
  
  // ... handler code
});
```

**Log Levels:**
- `logger.error()` - Errors only
- `logger.warn()` - Warnings
- `logger.info()` - General information
- `logger.debug()` - Detailed debugging

---

#### 3. Test Database Queries Directly

**Supabase SQL Editor:**
```sql
-- Test query directly
SELECT * FROM orders WHERE customer_id = 'uuid';

-- Check user permissions
SELECT * FROM users WHERE id = 'uuid';
```

**Verify Data:**
- Check table contents
- Verify foreign key relationships
- Test RLS policies

---

#### 4. Use Postman/Insomnia

**Benefits:**
- Bypass CORS issues
- Test API without frontend
- Inspect request/response
- Save requests for reuse

**Setup:**
1. Create collection: "Logistics Platform API"
2. Set base URL: `http://localhost:3000/api`
3. Add Authorization header: `Bearer <token>`
4. Test each endpoint

---

### Client-Side Debugging

#### 1. Browser DevTools

**Network Tab:**
- Inspect all API requests
- Check request headers
- View response data
- Identify failed requests

**Console Tab:**
- View JavaScript errors
- Check API error responses
- Debug authentication issues

**Application Tab:**
- Check localStorage (tokens)
- Verify environment variables
- Inspect session storage

---

#### 2. React DevTools

**Component Inspection:**
- View component state
- Check props
- Inspect context values
- Debug re-renders

**Redux DevTools (if used):**
- View state changes
- Time-travel debugging
- Action inspection

---

#### 3. Flutter Debugging

**Flutter DevTools:**
```bash
# Start app with debugging
flutter run --debug

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

**Debug Print:**
```dart
debugPrint('API Response: $response');
```

**Network Inspector:**
- Use `dio` interceptor for logging
- Check request/response details

---

## Troubleshooting Guides

### Issue: "Cannot log in"

**Symptoms:**
- Login fails with error
- User redirected back to login

**Troubleshooting Steps:**

1. **Check Credentials:**
   - Verify email/phone format
   - Check password/PIN is correct
   - Test with known working account

2. **Check Server:**
   ```bash
   # Verify server is running
   curl http://localhost:3000/health
   ```

3. **Check Database:**
   - Verify user exists in `users` table
   - Check `user_type` is correct
   - Verify driver status (not blocked/inactive)

4. **Check Authentication:**
   - Verify Supabase credentials in `.env`
   - Check Supabase Auth dashboard
   - Test token generation

5. **Check Logs:**
   ```bash
   # Server logs
   tail -f server/logs/error.log
   ```

6. **Test with Postman:**
   - Bypass frontend issues
   - Test API directly

---

### Issue: "Orders not loading"

**Symptoms:**
- Orders list is empty
- Loading spinner never stops
- Error message displayed

**Troubleshooting Steps:**

1. **Check Authentication:**
   - Verify token is valid
   - Test with `/api/auth/verify`

2. **Check API Response:**
   - Open browser DevTools → Network
   - Inspect `/api/orders` request
   - Check response status and data

3. **Check Database:**
   ```sql
   -- Verify orders exist
   SELECT * FROM orders;
   
   -- Check user permissions
   SELECT * FROM users WHERE id = 'user-uuid';
   ```

4. **Check Cache:**
   - Clear cache: `POST /api/admin/cache/clear`
   - Check if cache is causing stale data

5. **Check RLS Policies:**
   - Verify user can access orders
   - Check RLS policies in Supabase

6. **Check Server Logs:**
   ```bash
   tail -f server/logs/combined.log
   ```

---

### Issue: "Driver cannot see assigned orders"

**Symptoms:**
- Driver logged in successfully
- Orders list is empty
- Orders exist in database

**Troubleshooting Steps:**

1. **Check Order Assignment:**
   ```sql
   -- Verify order has driver_id
   SELECT id, driver_id, status FROM orders WHERE driver_id = 'driver-uuid';
   ```

2. **Check Driver ID:**
   - Verify driver is logged in with correct ID
   - Check `req.user.id` matches driver ID

3. **Check Order Status:**
   - Orders must be `assigned` or `in_transit`
   - Check status in database

4. **Check API Endpoint:**
   - Verify using `/api/drivers/me/orders`
   - Not `/api/orders` (that's for admins)

5. **Check Cache:**
   - Clear driver orders cache
   - Test without cache

6. **Check RLS Policies:**
   - Verify driver can view assigned orders
   - Check RLS policies allow access

---

### Issue: "Price calculation incorrect"

**Symptoms:**
- Order price seems wrong
- Price doesn't match expected

**Troubleshooting Steps:**

1. **Check Pricing Mode:**
   - Verify `pricingMode` in request
   - Check price card configuration

2. **Check Distance:**
   ```sql
   -- Verify distance calculation
   SELECT total_distance, total_distance_km FROM orders WHERE id = 'order-uuid';
   ```

3. **Check Price Cards:**
   ```sql
   -- View price cards
   SELECT * FROM price_cards;
   ```

4. **Check Pricing Service:**
   - Review `server/src/services/pricingService.js`
   - Add debug logging
   - Test with known inputs

5. **Check Environment Variables:**
   - Verify pricing configuration
   - Check default prices

6. **Test Manually:**
   - Calculate expected price
   - Compare with API response

---

### Issue: "Cache not working"

**Symptoms:**
- Slow API responses
- Cache status shows disconnected
- No cache hits in logs

**Troubleshooting Steps:**

1. **Check Redis:**
   ```bash
   # Test Redis connection
   redis-cli ping
   ```

2. **Check Redis URL:**
   ```env
   # .env file
   REDIS_URL=redis://localhost:6379
   ```

3. **Check Server Logs:**
   ```bash
   # Look for Redis connection errors
   grep -i redis server/logs/error.log
   ```

4. **Test Cache Manually:**
   ```bash
   # Connect to Redis
   redis-cli
   
   # Check keys
   KEYS *
   
   # Get value
   GET orders:list:all
   ```

5. **Check Cache Service:**
   - Review `server/src/services/cacheService.js`
   - Verify cache connection on startup

6. **Restart Services:**
   - Restart Redis
   - Restart server

---

## Error Response Codes Reference

### HTTP Status Codes

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 200 | OK | Success |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Validation error, invalid input |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Valid token but insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate resource (e.g., phone already exists) |
| 413 | Payload Too Large | File/request too large |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error, database error |
| 503 | Service Unavailable | Server overloaded, maintenance |

### Common Error Messages

| Message | Meaning | Solution |
|---------|---------|----------|
| "Token required" | Missing Authorization header | Add `Authorization: Bearer <token>` |
| "Invalid or expired token" | Token invalid/expired | Re-authenticate, get new token |
| "Not allowed by CORS" | Origin not allowed | Check CORS configuration |
| "Validation failed" | Request body invalid | Check required fields, data types |
| "Resource not found" | ID doesn't exist | Verify ID is correct |
| "Insufficient permissions" | User type not allowed | Check `user_type` matches requirement |
| "Database error" | Query failed | Check database connection, schema |
| "Rate limit exceeded" | Too many requests | Wait before retrying |

---

## Logging Best Practices

### What to Log

**Always Log:**
- Errors with stack traces
- Authentication failures
- Database errors
- Invalid requests

**Conditionally Log:**
- API requests (info level)
- Cache operations (debug level)
- Business logic steps (debug level)

**Never Log:**
- Passwords/PINs
- Full tokens (sanitize)
- Sensitive user data
- Credit card numbers

### Log Levels

**Error:**
- Exceptions
- Failed operations
- Critical issues

**Warn:**
- Deprecated features
- Performance issues
- Non-critical failures

**Info:**
- Request/response summaries
- Important business events
- System state changes

**Debug:**
- Detailed operation steps
- Cache hits/misses
- Internal state

---

## Monitoring and Alerts

### What to Monitor

**Server Health:**
- CPU usage
- Memory usage
- Response times
- Error rates

**Database:**
- Query performance
- Connection pool
- Slow queries
- Error rates

**Cache:**
- Hit rate
- Memory usage
- Connection status

**API:**
- Request volume
- Error rates by endpoint
- Response times
- Rate limit hits

### Alert Thresholds

**Critical:**
- Server down
- Database connection lost
- Error rate > 10%
- Response time > 5s

**Warning:**
- Error rate > 5%
- Response time > 2s
- Cache hit rate < 50%
- Memory usage > 80%

---

## Getting Help

### Before Asking for Help

1. **Check Logs:**
   - Server logs
   - Browser console
   - Database logs

2. **Reproduce Issue:**
   - Steps to reproduce
   - Expected vs actual behavior
   - Error messages

3. **Gather Information:**
   - Environment (dev/prod)
   - User type
   - Request/response details
   - Relevant logs

### Information to Provide

**Error Report Should Include:**
- Error message
- Stack trace (if available)
- Steps to reproduce
- Environment details
- Relevant code/logs
- Expected behavior

---

**End of README11.md**

**Next Section:** README12.md will cover Design Decisions & Trade-Offs in detail.
