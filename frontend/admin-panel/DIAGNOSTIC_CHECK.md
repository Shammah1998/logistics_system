# Login Timeout Diagnostic Guide

## Current Issue
Authentication is timing out after 15 seconds, indicating the Supabase auth call is not completing.

## Quick Checks

### 1. Verify Environment Variables
Check that `.env` file exists in `frontend/admin-panel/` with:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

**Important:** After creating/updating `.env`, restart the dev server:
```bash
cd frontend/admin-panel
npm run dev
```

### 2. Test Supabase Connection
Open browser console and check:
- Are there any CORS errors?
- Are there network errors in the Network tab?
- Is the Supabase URL correct?

### 3. Check Network Tab
1. Open DevTools (F12)
2. Go to Network tab
3. Try logging in
4. Look for requests to `*.supabase.co`
5. Check if they're:
   - Pending (not completing)
   - Failing (red status)
   - Blocked (CORS errors)

### 4. Verify Supabase Project Status
- Check Supabase dashboard: https://supabase.com/dashboard
- Verify project is active
- Check if there are any service issues

### 5. Test Direct API Call
In browser console, try:
```javascript
fetch('https://your-project.supabase.co/auth/v1/health', {
  method: 'GET'
}).then(r => r.json()).then(console.log).catch(console.error);
```

## Common Causes

1. **Incorrect Supabase URL**
   - Should be: `https://xxxxx.supabase.co`
   - Not: `http://localhost` or incorrect domain

2. **Missing/Incorrect Anon Key**
   - Get from Supabase Dashboard > Settings > API
   - Must start with `eyJ...`

3. **Network/Firewall Issues**
   - Corporate firewall blocking Supabase
   - VPN interfering
   - Internet connectivity issues

4. **CORS Issues**
   - Check browser console for CORS errors
   - Verify Supabase project settings allow your domain

5. **Supabase Service Issues**
   - Check Supabase status page
   - Verify project is not paused/suspended

## Next Steps

If timeout persists:
1. Check browser console for specific errors
2. Verify environment variables are loaded (check console logs)
3. Test Supabase connection directly
4. Check Network tab for failed requests
5. Verify Supabase project is active



