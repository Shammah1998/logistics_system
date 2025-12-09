# Fix Remaining Security Warnings

You have 2 remaining warnings. Here's how to fix both:

---

## 1. Function Search Path Mutable ✅ (Code Fix)

### Problem
The `count_orders_by_status()` function is missing `SET search_path = public`, which is a security best practice.

### Solution
Run the SQL migration:

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy and paste the contents of `server/database/fix_remaining_security_warnings.sql`
3. Click **Run**
4. Wait a few minutes for Supabase to re-analyze
5. Check **Database** → **Advisor** - the warning should disappear

---

## 2. Leaked Password Protection ⚙️ (Dashboard Setting)

### Problem
Supabase Auth's leaked password protection is disabled. This feature checks passwords against HaveIBeenPwned.org to prevent users from using compromised passwords.

### Solution
Enable it in the Supabase Dashboard:

1. Go to **Supabase Dashboard** → **Authentication** → **Settings**
2. Scroll down to **Password Security** section
3. Find **"Leaked Password Protection"** toggle
4. **Enable** it
5. Save changes

### What This Does
- Checks user passwords against HaveIBeenPwned.org database
- Prevents users from using passwords that have been leaked in data breaches
- Enhances security without affecting user experience
- Works automatically - no code changes needed

### Screenshot Location
The setting is typically located at:
```
Supabase Dashboard → Authentication → Settings → Password Security → Leaked Password Protection
```

---

## After Fixing Both

1. Wait 5-10 minutes for Supabase to re-analyze
2. Check **Database** → **Advisor**
3. All warnings should be resolved! ✅

---

**Both fixes are simple and safe!** 🎉

