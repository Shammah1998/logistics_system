# 🚨 CRITICAL BUG FOUND: Property Name Mismatch

## The Problem

**Location:** `server/src/middleware/auth.js` vs `server/src/routes/orderRoutes.js`

**Issue:** Property name inconsistency between middleware and routes.

### In `auth.js` (line 71-74):
```javascript
req.user = {
  id: user.id,
  email: user.email,
  userType: userData.user_type  // ← Uses camelCase: userType
};
```

### In `orderRoutes.js` (line 132):
```javascript
const userType = req.user.user_type;  // ← Tries to access snake_case: user_type
```

**Result:** `userType` is `undefined` → Admin panel fails!

---

## Impact

- ❌ All admin routes fail because `userType` is undefined
- ❌ Order filtering doesn't work
- ❌ Cache keys are incorrect
- ❌ Admin panel shows loading forever

---

## Fix Required

**Option 1: Change middleware to use snake_case (consistent with database)**
```javascript
req.user = {
  id: user.id,
  email: user.email,
  user_type: userData.user_type  // ← Change to snake_case
};
```

**Option 2: Change all routes to use camelCase (consistent with JavaScript)**
```javascript
const userType = req.user.userType;  // ← Change to camelCase
```

**Recommendation:** Use **Option 1** (snake_case) because:
- Database uses snake_case (`user_type`)
- More consistent with backend conventions
- Less changes needed

---

## Files That Need Fixing

1. ✅ `server/src/middleware/auth.js` - Change `userType` to `user_type`
2. ⚠️ `server/src/routes/orderRoutes.js` - Already uses `user_type` (correct)
3. ⚠️ `server/src/middleware/auth.js` - `requireUserType` uses `userType` (needs fix)

---

## Additional Issues Found

### In `auth.js` line 95:
```javascript
if (!allowedTypes.includes(req.user.userType)) {  // ← Uses camelCase
```

This also needs to be changed to `user_type`.

---

## Complete Fix

Change `server/src/middleware/auth.js`:

**Before:**
```javascript
req.user = {
  id: user.id,
  email: user.email,
  userType: userData.user_type
};

// ... later ...

if (!allowedTypes.includes(req.user.userType)) {
```

**After:**
```javascript
req.user = {
  id: user.id,
  email: user.email,
  user_type: userData.user_type  // ← Changed to snake_case
};

// ... later ...

if (!allowedTypes.includes(req.user.user_type)) {  // ← Changed to snake_case
```

---

**This is the root cause of the admin panel loading issue!**

