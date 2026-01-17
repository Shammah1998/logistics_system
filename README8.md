# Logistics Platform - Security Model

## Security Model

This section explains the comprehensive security architecture of the Logistics Platform. Security is implemented at multiple layers: authentication, authorization, data protection, network security, and application-level security. Every security decision is intentional and serves a specific purpose.

---

## Authentication Architecture

### Overview

The platform uses **Supabase Auth** as the authentication provider, which handles user authentication, password hashing, and session management. All three client applications (Admin Panel, Customer Panel, Driver Mobile App) authenticate through Supabase, but use different authentication flows based on user type.

### Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                          │
└─────────────────────────────────────────────────────────────────┘

1. USER ENTERS CREDENTIALS
   │
   ├─ Customer/Admin: Email + Password
   └─ Driver: Phone Number + PIN
   
2. CLIENT SENDS CREDENTIALS
   │
   ├─ Web Apps: Supabase Auth SDK (signInWithPassword)
   └─ Mobile App: Custom API endpoint (/api/auth/drivers/login)
   
3. SUPABASE AUTH VALIDATES
   │
   ├─ Checks email/phone exists
   ├─ Verifies password/PIN hash
   ├─ Generates JWT token
   └─ Returns session with access_token and refresh_token
   
4. TOKEN STORAGE
   │
   ├─ Web Apps: localStorage (browser)
   └─ Mobile App: SharedPreferences (device storage)
   
5. TOKEN USAGE
   │
   └─ All API requests include: Authorization: Bearer <token>
   
6. TOKEN VERIFICATION
   │
   ├─ Backend extracts token from Authorization header
   ├─ Verifies token with Supabase Auth API
   ├─ Fetches user_type from database
   └─ Attaches user object to request
```

### Customer & Admin Authentication

**Method:** Email + Password via Supabase Auth

**Process:**
1. User enters email and password in web app
2. Frontend calls `supabase.auth.signInWithPassword({ email, password })`
3. Supabase Auth validates credentials
4. Returns JWT token and session
5. Token stored in browser localStorage
6. Token included in all API requests

**Why This Method:**
- **Standard**: Email/password is the most common authentication method
- **Secure**: Supabase handles password hashing (bcrypt)
- **Convenient**: Users can use existing email accounts
- **Recovery**: Supabase provides password reset functionality

**Security Features:**
- **Password Hashing**: Supabase uses bcrypt (industry standard)
- **Token Expiration**: JWT tokens have expiration times
- **Refresh Tokens**: Automatic token refresh via Supabase SDK
- **Session Management**: Supabase handles session persistence

### Driver Authentication

**Method:** Phone Number + PIN via Custom API Endpoint

**Process:**
1. Driver enters phone number and PIN in mobile app
2. App sends POST to `/api/auth/drivers/login` with `{ phone, password }`
3. Backend normalizes phone number to +254 format
4. Backend generates expected email: `driver_<phone>@drivers.xobo.co.ke`
5. Backend calls Supabase Auth: `signInWithPassword({ email, password })`
6. Supabase validates credentials
7. Backend returns JWT token + user data
8. Token stored in SharedPreferences
9. Token included in all API requests

**Why This Method:**
- **Mobile-First**: Drivers use phones, not emails
- **Simple**: PIN is easier to remember than complex passwords
- **Deterministic Email**: Phone-to-email mapping ensures consistency
- **Backend Control**: Backend can handle phone normalization and validation

**Phone Number Normalization:**
- Input: `0712345678`, `712345678`, `+254712345678`
- Normalized: `+254712345678` (always)
- Email Generated: `driver_254712345678@drivers.xobo.co.ke`

**Why Normalization:**
- **Consistency**: Same phone number always maps to same email
- **International Format**: Supports international phone numbers
- **Database Integrity**: Prevents duplicate accounts with different formats

**Security Features:**
- **PIN Hashing**: Stored as hashed password in Supabase Auth
- **Phone Validation**: Backend validates phone format
- **Status Check**: Blocks inactive/blocked drivers from logging in
- **Auto-Fix**: Creates missing user records automatically

---

## Authorization (Role-Based Access Control)

### User Types

The system has three user types, each with different permissions:

**1. Customer (`user_type = 'customer'`)**
- **Can Do:**
  - Create orders
  - View own orders
  - Track own orders
  - Update own profile
- **Cannot Do:**
  - View other customers' orders
  - Assign drivers
  - Approve PODs
  - Manage drivers or customers

**2. Driver (`user_type = 'driver'`)**
- **Can Do:**
  - View assigned orders
  - Update order status (assigned → in_transit)
  - Upload PODs for assigned orders
  - View own wallet and earnings
  - Request withdrawals
  - Update own profile
- **Cannot Do:**
  - View other drivers' orders
  - Assign orders to themselves
  - Approve PODs
  - View other drivers' wallets

**3. Admin (`user_type = 'admin'`)**
- **Can Do:**
  - View all orders
  - Assign orders to drivers
  - Approve/reject PODs
  - Manage drivers (create, update, delete)
  - View all customers
  - View dashboard statistics
  - Manage cache
  - View system health
- **Cannot Do:**
  - Nothing (full access)

### Authorization Implementation

**Backend Authorization:**

**Middleware:** `server/src/middleware/auth.js`

**`authenticate` Middleware:**
- Extracts JWT token from `Authorization: Bearer <token>` header
- Verifies token with Supabase Auth API
- Fetches `user_type` from `users` table
- Attaches `{ id, email, user_type }` to `req.user`
- Returns 401 if token missing or invalid

**`requireUserType(...allowedTypes)` Middleware:**
- Checks if `req.user.user_type` is in `allowedTypes` array
- Returns 403 if user type not allowed
- Used like: `router.use(requireUserType('admin'))`

**Usage Example:**
```javascript
// All routes require authentication
router.use(authenticate);

// Only admins can access this route
router.get('/drivers', requireUserType('admin'), async (req, res) => {
  // req.user is available here
  const userId = req.user.id;
  const userType = req.user.user_type; // 'admin'
});
```

**Frontend Authorization:**

**Protected Routes:**
- React apps use `ProtectedRoute` component
- Checks authentication state from Context
- Redirects to login if not authenticated
- Admin panel also checks `userType === 'admin'`

**Flutter App:**
- `main.dart` watches `authProvider` state
- Shows `HomePage` if authenticated
- Shows `LoginPage` if not authenticated
- No role-based checks (drivers only)

**Database Authorization (RLS):**

**Row Level Security Policies:**
- Database-level access control
- Policies defined in `server/database/rls_policies.sql`
- Enforced by Supabase PostgreSQL

**Key Policies:**

**Users Table:**
- Users can view/update own profile
- Admins can view/update all users

**Orders Table:**
- Customers can view/update own orders (if pending)
- Drivers can view assigned orders
- Admins can view/update all orders

**Wallets Table:**
- Drivers can view own wallet
- Admins can view all wallets

**PODs Table:**
- Drivers can view/submit PODs for assigned orders
- Customers can view PODs for own orders
- Admins can view/update all PODs

**Why RLS:**
- **Defense in Depth**: Even if application code has bugs, database enforces access
- **Multi-Tenancy**: Supports multiple companies securely
- **Compliance**: Meets data protection requirements
- **Audit Trail**: Database logs all access attempts

**RLS Bypass:**
- Backend uses `SUPABASE_SERVICE_ROLE_KEY` to bypass RLS
- **Why**: Backend is trusted and needs to perform operations RLS would restrict
- **Security**: Service role key is never exposed to clients
- **Use Cases**: Admin operations, cross-user queries, system operations

---

## Session Management

### Web Applications (Admin & Customer Panels)

**Storage:** Browser localStorage

**Implementation:**
- Supabase Auth SDK handles session persistence
- Token stored with key: `sb-<project-ref>-auth-token`
- Session automatically restored on page reload
- Token refresh handled automatically by Supabase SDK

**Session Lifecycle:**
1. User logs in → Token stored in localStorage
2. User navigates → Token persists across page changes
3. User closes browser → Token remains (until expiration)
4. User reopens browser → Supabase SDK checks token validity
5. Token expired → User redirected to login

**Security Considerations:**
- **XSS Protection**: localStorage vulnerable to XSS attacks
- **Mitigation**: Input sanitization, Content Security Policy
- **Token Expiration**: Tokens expire after set time
- **Refresh Tokens**: Automatic refresh extends session

### Mobile Application (Flutter)

**Storage:** SharedPreferences (device storage)

**Implementation:**
- Token stored with key: `'auth_token'`
- Token persists across app restarts
- App verifies token on startup

**Session Lifecycle:**
1. Driver logs in → Token stored in SharedPreferences
2. Driver closes app → Token persists
3. Driver reopens app → App verifies token via `/api/auth/verify`
4. Token valid → Driver stays logged in
5. Token invalid → Driver redirected to login

**Security Considerations:**
- **Device Storage**: SharedPreferences is not encrypted by default
- **Mitigation**: Consider `flutter_secure_storage` for production
- **Token Verification**: App verifies token on every startup
- **Automatic Cleanup**: Invalid tokens are removed automatically

**Why SharedPreferences:**
- **Simplicity**: Easy to use, no additional dependencies
- **Persistence**: Survives app restarts
- **Performance**: Fast read/write operations

**Production Recommendation:**
- Use `flutter_secure_storage` package for encrypted storage
- Provides additional security layer

---

## Token Management

### JWT Token Structure

**Token Type:** JSON Web Token (JWT)

**Token Components:**
- **Header**: Algorithm and token type
- **Payload**: User ID, email, expiration time
- **Signature**: Cryptographically signed by Supabase

**Token Contents:**
- User ID (UUID)
- Email address
- Expiration timestamp
- Issued at timestamp

**What's NOT in Token:**
- Password or PIN
- User type (fetched from database for security)
- Sensitive user data

**Why JWT:**
- **Stateless**: Server doesn't need to store sessions
- **Scalable**: Works across multiple servers
- **Standard**: Industry-standard authentication method
- **Secure**: Cryptographically signed, tamper-proof

### Token Lifecycle

```
1. TOKEN GENERATION
   │
   ├─ User logs in
   ├─ Supabase Auth generates JWT
   └─ Token includes: user_id, email, exp, iat
   
2. TOKEN STORAGE
   │
   ├─ Web: localStorage
   └─ Mobile: SharedPreferences
   
3. TOKEN USAGE
   │
   ├─ Included in Authorization header
   ├─ Format: Authorization: Bearer <token>
   └─ Sent with every API request
   
4. TOKEN VERIFICATION
   │
   ├─ Backend extracts token from header
   ├─ Verifies signature with Supabase
   ├─ Checks expiration
   ├─ Fetches user_type from database
   └─ Attaches user to request
   
5. TOKEN EXPIRATION
   │
   ├─ Token expires after set time
   ├─ Web: Supabase SDK refreshes automatically
   ├─ Mobile: App must handle refresh (or re-login)
   └─ Expired tokens return 401 Unauthorized
   
6. TOKEN REVOCATION
   │
   ├─ User logs out → Token removed from storage
   ├─ Token remains valid until expiration
   └─ No server-side blacklist (stateless design)
```

### Token Security Measures

**1. Token Sanitization in Logs:**
- All response bodies sanitized before logging
- Tokens automatically redacted from debug output
- Prevents token exposure in logs

**Implementation (Flutter):**
```dart
String _sanitizeResponseBody(String body) {
  // Removes tokens from logged responses
  // Handles multiple token formats
  // Returns sanitized JSON
}
```

**Why This Matters:**
- **Log Security**: Logs may be stored or shared
- **Debug Safety**: Developers can debug without exposing tokens
- **Compliance**: Meets security audit requirements

**2. HTTPS Only (Production):**
- All API communication uses HTTPS
- Prevents token interception
- Certificate validation ensures secure connection

**3. Token in Headers Only:**
- Tokens never sent in URL parameters
- URL parameters may be logged by servers/proxies
- Headers are more secure

**4. No Token in Response Bodies:**
- Tokens only returned during login
- Subsequent responses don't include tokens
- Reduces token exposure risk

---

## Data Protection

### Password/PIN Security

**Storage:**
- Passwords/PINs stored in Supabase Auth (not in application database)
- Hashed using bcrypt algorithm
- Never stored in plain text
- Never logged or transmitted in logs

**Hashing:**
- Supabase uses bcrypt with salt
- Industry-standard password hashing
- Resistant to rainbow table attacks
- Computationally expensive (prevents brute force)

**Transmission:**
- Passwords/PINs sent over HTTPS only
- Never logged in request/response bodies
- Sanitized from all debug output

**Why bcrypt:**
- **Proven**: Industry standard for password hashing
- **Secure**: Designed to be slow (prevents brute force)
- **Managed**: Handled by Supabase, no manual implementation needed

### Sensitive Data Protection

**Financial Data:**
- Wallet balances stored as NUMERIC (precise decimal)
- Transactions encrypted in transit (HTTPS)
- Withdrawal requests require admin approval
- Audit trail in `transactions` table

**Personal Data:**
- Phone numbers normalized but not encrypted
- Email addresses stored as-is (required for authentication)
- Addresses stored as JSONB (structured data)
- No encryption at rest (Supabase handles this)

**Why No Encryption at Rest:**
- **Supabase Responsibility**: Supabase handles database encryption
- **Performance**: Application-level encryption adds complexity
- **Key Management**: Supabase manages encryption keys securely

### Database Security

**Row Level Security (RLS):**
- Enabled on all tables
- Policies enforce access control at database level
- Prevents unauthorized data access
- Works even if application code has bugs

**Service Role Key:**
- Backend uses service role key to bypass RLS
- **Why**: Backend needs to perform operations RLS would restrict
- **Security**: Service role key never exposed to clients
- **Storage**: Only in server `.env` file (never committed to git)

**Connection Security:**
- All database connections use SSL/TLS
- Supabase enforces encrypted connections
- Connection strings include SSL parameters

---

## Network Security

### HTTPS/TLS

**Production:**
- All API communication uses HTTPS
- SSL certificates validated
- Prevents man-in-the-middle attacks
- Encrypts data in transit

**Development:**
- Local development may use HTTP
- **Why**: Easier setup, no certificate management
- **Risk**: Only affects local development
- **Mitigation**: Production always uses HTTPS

### CORS (Cross-Origin Resource Sharing)

**Configuration:** `server/src/server.js`

**Allowed Origins:**
- Development: All localhost origins
- Production: Specific frontend URLs (from environment variables)
- Vercel: All `*.vercel.app` domains (for preview deployments)

**Why This Configuration:**
- **Security**: Prevents unauthorized websites from accessing API
- **Flexibility**: Supports multiple client applications
- **Development**: Allows localhost for development
- **Preview Deployments**: Supports Vercel preview URLs

**CORS Headers:**
- `Access-Control-Allow-Origin`: Specific allowed origins
- `Access-Control-Allow-Credentials`: true (for cookies/tokens)
- `Access-Control-Allow-Methods`: GET, POST, PUT, DELETE, PATCH
- `Access-Control-Allow-Headers`: Content-Type, Authorization

**Why Credentials:**
- Allows cookies and Authorization headers
- Required for JWT token authentication
- Enables secure cross-origin requests

### Rate Limiting

**Implementation:** `server/src/middleware/rateLimiter.js`

**Configuration:**
- **Window**: 15 minutes
- **Max Requests**: 100 (production), 1000 (development)
- **Scope**: Per IP address

**Why Rate Limiting:**
- **Prevents Abuse**: Stops API abuse and DoS attacks
- **Resource Protection**: Protects server resources
- **Fair Usage**: Ensures fair access for all users

**Exclusions:**
- Health check endpoint (`/health`) - never rate limited
- Localhost in development - excluded for developer convenience

**Why These Exclusions:**
- **Health Checks**: Monitoring tools need frequent checks
- **Development**: Developers need to test without limits

---

## File Upload Security

### POD (Proof of Delivery) Uploads

**Current Status:** Placeholder implementation (endpoint exists but not fully implemented)

**Planned Security Measures:**

**1. File Type Validation:**
- Only allow image formats (JPEG, PNG)
- Reject executable files and scripts
- Validate MIME types, not just extensions

**2. File Size Limits:**
- Maximum file size (e.g., 5MB)
- Prevents DoS attacks via large files
- Reduces storage costs

**3. Storage Location:**
- Files stored in Supabase Storage
- Organized by order ID
- Access controlled via RLS policies

**4. Virus Scanning:**
- Scan uploaded files (future enhancement)
- Block malicious files
- Protect system and users

**5. Access Control:**
- Only drivers can upload PODs
- Only for assigned orders
- Verified via authentication middleware

**Why These Measures:**
- **Malware Prevention**: Prevents malicious file uploads
- **Storage Security**: Files stored securely, access controlled
- **Resource Protection**: Prevents storage abuse

---

## API Security

### Request Validation

**Input Validation:**
- All request bodies validated before processing
- Uses `express-validator` for validation
- Validates data types, formats, ranges
- Returns 400 Bad Request for invalid data

**Example (Order Creation):**
```javascript
validateCreateOrder = [
  body('vehicle_type').isIn(['small', 'medium', 'large']),
  body('pricing_mode').isIn(['distance_based', 'per_box']),
  body('pickup_address.coordinates.lat').isFloat({ min: -90, max: 90 }),
  // ... more validations
]
```

**Why Validation:**
- **Data Integrity**: Ensures data meets requirements
- **Security**: Prevents injection attacks
- **User Experience**: Clear error messages for invalid input

### SQL Injection Prevention

**Method:** Parameterized Queries via Supabase Client

**Implementation:**
- Supabase client uses parameterized queries
- Never concatenate user input into SQL
- All queries use Supabase's query builder

**Example (Safe):**
```javascript
const { data } = await supabase
  .from('orders')
  .select('*')
  .eq('customer_id', userId) // Parameterized, safe
```

**Example (Unsafe - Never Do This):**
```javascript
// NEVER DO THIS:
const query = `SELECT * FROM orders WHERE customer_id = '${userId}'`;
// This is vulnerable to SQL injection
```

**Why Supabase Client:**
- **Built-in Protection**: Supabase client prevents SQL injection
- **Type Safety**: Query builder provides type safety
- **Best Practice**: Industry-standard approach

### XSS (Cross-Site Scripting) Prevention

**Frontend Protection:**
- React automatically escapes content in JSX
- Prevents XSS attacks in rendered content
- User input is sanitized before display

**Backend Protection:**
- Response data is JSON (not HTML)
- No user input rendered as HTML
- Content-Type headers set correctly

**Why This Works:**
- **React Escaping**: React escapes all content by default
- **JSON Responses**: API returns JSON, not HTML
- **No Eval**: Never use `eval()` or `innerHTML` with user input

---

## Security Headers

### Helmet.js Middleware

**Implementation:** `server/src/server.js`

**What It Does:**
- Sets security-related HTTP headers
- Prevents common web vulnerabilities
- Configures Content Security Policy

**Headers Set:**
- `X-Content-Type-Options: nosniff` - Prevents MIME type sniffing
- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-XSS-Protection: 1; mode=block` - Enables XSS protection
- `Strict-Transport-Security` - Enforces HTTPS (production)
- `Content-Security-Policy` - Restricts resource loading

**Why Helmet:**
- **Best Practice**: Industry-standard security middleware
- **Easy**: One line of code adds multiple security headers
- **Maintained**: Regularly updated for new threats

---

## Error Handling Security

### Error Message Sanitization

**Production:**
- Generic error messages: "Internal server error"
- No stack traces exposed
- No sensitive information in errors

**Development:**
- Detailed error messages
- Stack traces included
- Helps debugging

**Implementation:**
```javascript
const message = process.env.NODE_ENV === 'production' 
  ? 'Internal server error' 
  : err.message;
```

**Why This Approach:**
- **Security**: Prevents information leakage in production
- **Debugging**: Developers get detailed errors in development
- **User Experience**: Users see friendly error messages

### Authentication Error Handling

**Login Failures:**
- Generic message: "Invalid credentials"
- Doesn't reveal if email/phone exists
- Prevents user enumeration attacks

**Token Errors:**
- 401 Unauthorized for invalid/expired tokens
- Generic message: "Authentication required"
- Doesn't reveal token validation details

**Why Generic Messages:**
- **Security**: Prevents information leakage
- **Privacy**: Doesn't reveal if account exists
- **Best Practice**: Industry-standard approach

---

## Audit and Logging

### Audit Logs

**Table:** `audit_logs`

**What's Logged:**
- User actions (who did what)
- Entity changes (what changed)
- IP addresses and user agents
- Timestamps

**Why Audit Logs:**
- **Compliance**: Required for financial and operational audits
- **Security**: Tracks suspicious activity
- **Debugging**: Helps trace issues
- **Accountability**: Knows who made changes

### Application Logging

**Implementation:** `server/src/utils/logger.js` (Winston)

**Log Levels:**
- **info**: General information
- **warn**: Warnings
- **error**: Errors with stack traces

**What's Logged:**
- API requests (method, path, IP)
- Errors (with stack traces)
- Important operations (order creation, POD approval)
- Cache operations

**What's NOT Logged:**
- Passwords/PINs (never logged)
- Tokens (sanitized from logs)
- Sensitive user data

**Log Storage:**
- Development: Files in `server/logs/`
- Production: External logging service (Render logs)

**Why Winston:**
- **Structured**: Supports structured logging
- **Flexible**: Multiple transports (console, file, external)
- **Standard**: Industry-standard logging library

---

## Security Best Practices Implemented

### ✅ Implemented

**Authentication:**
- ✅ Password hashing (bcrypt via Supabase)
- ✅ JWT token authentication
- ✅ Token expiration
- ✅ Secure token storage
- ✅ Token verification on every request

**Authorization:**
- ✅ Role-based access control
- ✅ Database-level RLS policies
- ✅ Middleware-based route protection
- ✅ Frontend route protection

**Network Security:**
- ✅ HTTPS in production
- ✅ CORS configuration
- ✅ Rate limiting
- ✅ Security headers (Helmet)

**Data Protection:**
- ✅ Input validation
- ✅ SQL injection prevention (parameterized queries)
- ✅ XSS prevention (React escaping)
- ✅ Token sanitization in logs

**Error Handling:**
- ✅ Generic error messages in production
- ✅ No sensitive data in errors
- ✅ Proper HTTP status codes

### 🔄 Recommended Enhancements

**Token Security:**
- 🔄 Token refresh mechanism (mobile app)
- 🔄 Token blacklisting on logout
- 🔄 Shorter token expiration times
- 🔄 Biometric authentication (mobile)

**Data Encryption:**
- 🔄 Encrypted storage for mobile tokens (flutter_secure_storage)
- 🔄 Field-level encryption for sensitive data
- 🔄 Database encryption at rest (Supabase handles this)

**File Upload:**
- 🔄 File type validation
- 🔄 File size limits
- 🔄 Virus scanning
- 🔄 Image optimization

**Monitoring:**
- 🔄 Security event logging
- 🔄 Failed login attempt tracking
- 🔄 Suspicious activity detection
- 🔄 Rate limiting per user (not just IP)

---

## Security Configuration

### Environment Variables (Security-Sensitive)

**Server (.env):**
- `SUPABASE_SERVICE_ROLE_KEY` - **CRITICAL**: Never expose to clients
- `SUPABASE_URL` - Public, but keep secure
- `REDIS_PASSWORD` - Keep secure if using Redis

**Client Apps (.env):**
- `VITE_SUPABASE_ANON_KEY` - Public (safe to expose)
- `VITE_SUPABASE_URL` - Public (safe to expose)
- `VITE_API_URL` - Public (safe to expose)

**Why Service Role Key is Critical:**
- **Full Access**: Bypasses all RLS policies
- **Database Access**: Can read/write all data
- **Never Expose**: Must never be in client code
- **Backend Only**: Only used by server

### Production Security Checklist

**Before Deployment:**
- ✅ All `.env` files excluded from git
- ✅ Service role key only in server environment
- ✅ HTTPS enabled for all endpoints
- ✅ CORS configured for production URLs only
- ✅ Rate limiting enabled
- ✅ Security headers configured
- ✅ Error messages sanitized
- ✅ Logging configured (no sensitive data)
- ✅ Database RLS policies enabled
- ✅ Strong passwords for all accounts

---

## Security Incident Response

### If Token is Compromised

**Immediate Actions:**
1. User should log out (removes token from storage)
2. User should change password/PIN
3. Monitor for suspicious activity
4. Revoke token if possible (requires token blacklist)

**Prevention:**
- Token expiration limits exposure window
- HTTPS prevents token interception
- Secure storage prevents token theft

### If Database is Compromised

**Immediate Actions:**
1. Rotate all credentials (Supabase keys, Redis password)
2. Review audit logs for unauthorized access
3. Notify affected users
4. Review and strengthen security measures

**Protection:**
- RLS policies limit damage scope
- Service role key is separate from user credentials
- Audit logs help identify breach scope

### If API is Abused

**Immediate Actions:**
1. Review rate limiting logs
2. Block offending IP addresses
3. Increase rate limits if needed
4. Review and strengthen validation

**Protection:**
- Rate limiting prevents abuse
- Input validation prevents injection attacks
- CORS prevents unauthorized origins

---

## Compliance Considerations

### Data Protection

**User Data:**
- Stored securely in Supabase (encrypted at rest)
- Access controlled via RLS policies
- Audit trail in `audit_logs` table

**Financial Data:**
- Precise decimal storage (no rounding errors)
- Complete transaction history
- Withdrawal approval workflow

**Personal Data:**
- Phone numbers and emails stored securely
- Addresses stored as structured data
- No unnecessary data collection

### GDPR Considerations (Future)

**If Applicable:**
- User data export functionality
- User data deletion (right to be forgotten)
- Consent management
- Privacy policy acceptance

**Current State:**
- Data stored securely
- Access controlled
- Audit trail maintained

---

## Security Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                               │
└─────────────────────────────────────────────────────────────────┘

LAYER 1: NETWORK SECURITY
   • HTTPS/TLS encryption
   • CORS restrictions
   • Rate limiting
   • Security headers (Helmet)

LAYER 2: AUTHENTICATION
   • Supabase Auth (password hashing)
   • JWT token authentication
   • Token verification
   • Secure token storage

LAYER 3: AUTHORIZATION
   • Role-based access control (RBAC)
   • Middleware-based route protection
   • Database RLS policies
   • Frontend route protection

LAYER 4: DATA PROTECTION
   • Input validation
   • SQL injection prevention
   • XSS prevention
   • Error message sanitization

LAYER 5: AUDIT & MONITORING
   • Audit logs
   • Application logging
   • Security event tracking
   • Error tracking
```

**Why Multiple Layers:**
- **Defense in Depth**: If one layer fails, others provide protection
- **Comprehensive**: Covers all attack vectors
- **Best Practice**: Industry-standard security architecture

---

**End of README8.md**

**Next Section:** README9.md will cover Installation & Setup with zero-assumption instructions.
