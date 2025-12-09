# Security Fixes for Supabase Warnings

This document explains the security warnings from Supabase and how to fix them.

## Fixed Issues

### ✅ 1. Function Search Path Mutable (6 functions fixed)

**What it means:**
Functions without a fixed `search_path` can be vulnerable to SQL injection attacks. An attacker could potentially manipulate the search path to execute malicious code.

**Functions Fixed:**
- `update_updated_at_column()`
- `update_driver_credentials_updated_at()`
- `generate_order_number()`
- `create_driver_wallet()`
- `get_user_type()`
- `handle_new_user()`

**Solution Applied:**
All functions now have `SET search_path = public` in their definition, which locks the search path to the `public` schema only.

**How to Apply:**
Run the migration file in Supabase SQL Editor:
```sql
-- Copy and paste the contents of fix_security_warnings.sql
-- into the Supabase SQL Editor and execute it
```

**Location:** `server/database/fix_security_warnings.sql`

---

### ⚠️ 2. Leaked Password Protection Disabled

**What it means:**
Supabase can check user passwords against known leaked password databases (like Have I Been Pwned) to prevent users from using compromised passwords.

**How to Enable (Step-by-Step):**

1. **Open Supabase Dashboard:**
   - Go to https://supabase.com/dashboard
   - Select your project: **Logistics** (or your project name)

2. **Navigate to Authentication Settings:**
   - In the left sidebar, click **"Authentication"**
   - Then click **"Settings"** (or go directly to: Authentication → Settings)

3. **Find Password Protection Section:**
   - Scroll down in the Settings page
   - Look for the **"Password Protection"** section
   - You should see a toggle/checkbox for **"Leaked Password Protection"**

4. **Enable the Feature:**
   - Toggle ON **"Leaked Password Protection"**
   - The setting should save automatically (or click "Save" if there's a button)

5. **Verify:**
   - Go back to **Advisors** → **Security Advisor**
   - Click **"Refresh"** button or wait 1-2 minutes
   - The warning should disappear

**Alternative Path (if above doesn't work):**
- Go to: **Project Settings** → **Auth** → **Password Protection**
- Enable **"Leaked Password Protection"**

**Note:** This is a dashboard setting and cannot be fixed via SQL migration. You must enable it manually in the Supabase dashboard. If you don't see this option, it might be a paid feature - check your Supabase plan.

---

## Verification

After applying the fixes:

1. **For Function Search Path:**
   - Go to Supabase Dashboard → **Advisors** → **Security Advisor**
   - The 6 "Function Search Path Mutable" warnings should disappear
   - If they don't, refresh the advisor or wait a few minutes

2. **For Leaked Password Protection:**
   - Go to Supabase Dashboard → **Authentication** → **Settings**
   - Verify that "Leaked Password Protection" is enabled
   - The warning should disappear from Security Advisor

---

## Best Practices

- Always set `SET search_path` in database functions
- Use `SECURITY DEFINER` only when necessary (functions that need elevated privileges)
- Enable all security features in Supabase dashboard
- Regularly review Security Advisor warnings

