# Backend API Debugging Guide

## Issue
Backend API appears to not be working correctly - empty data shown in Orders, Drivers, and Customers pages.

## Possible Causes

### 1. Backend Server Not Running (Local Development)
- Check if backend is running on `localhost:3000`
- Check terminal for backend server logs
- Verify no errors in backend console

### 2. API URL Configuration
- **Development**: Should use Vite proxy (`/api` → `localhost:3000`)
- **Production**: Should use `VITE_API_URL` from environment variables
- Check browser Network tab to see actual API URLs being called

### 3. Authentication Issues
- Token might be expired
- Token might not be sent correctly
- Check `Authorization` header in Network tab

### 4. Database Queries Returning Empty
- **This is NORMAL if database is empty!**
- No orders = empty orders list
- No drivers = empty drivers list
- No customers = empty customers list

### 5. Silent Errors
- Backend might be returning errors but frontend isn't showing them
- Check browser console for errors
- Check Network tab for failed requests

## How to Debug

### Step 1: Check Browser Console
1. Open DevTools (F12)
2. Go to Console tab
3. Look for:
   - Red error messages
   - Failed API calls
   - Network errors

### Step 2: Check Network Tab
1. Open DevTools (F12)
2. Go to Network tab
3. Filter by "XHR" or "Fetch"
4. Click on API requests (e.g., `/api/orders`, `/api/drivers`)
5. Check:
   - **Status Code**: Should be 200 (not 401, 403, 500)
   - **Response**: Click "Response" tab to see what backend returned
   - **Headers**: Check if `Authorization` header is present

### Step 3: Check Backend Logs
1. Check terminal where backend is running
2. Look for:
   - Error messages
   - Database query errors
   - Authentication errors

### Step 4: Test API Directly
Open browser and go to:
- `http://localhost:3000/api/health` (should return server status)
- `http://localhost:3000/api/dashboard/stats` (requires auth token)

## Expected Behavior

### If Database is Empty:
- ✅ API returns `{ success: true, data: [] }`
- ✅ Frontend shows "No orders yet", "No drivers yet", etc.
- ✅ This is CORRECT behavior

### If Database Has Data:
- ✅ API returns `{ success: true, data: [...] }`
- ✅ Frontend displays the data
- ✅ Tables populate with data

## Common Issues

### Issue: 401 Unauthorized
**Cause**: Token expired or invalid
**Fix**: Log out and log back in

### Issue: 500 Internal Server Error
**Cause**: Backend error (database, code bug)
**Fix**: Check backend logs for error details

### Issue: CORS Error
**Cause**: Backend CORS not configured correctly
**Fix**: Check `ADMIN_PANEL_URL` in backend environment variables

### Issue: Network Error / Failed to Fetch
**Cause**: Backend not running or wrong URL
**Fix**: 
- Verify backend is running
- Check `VITE_API_URL` in frontend environment variables

## Next Steps

1. **Check browser console** - Share any errors you see
2. **Check Network tab** - Share the status codes and response bodies
3. **Check backend terminal** - Share any error messages
4. **Verify backend is running** - Is `localhost:3000` accessible?

---

**The code has been updated with better error handling. Please check the browser console and Network tab to see what's actually happening.**

