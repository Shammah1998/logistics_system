# RLS Performance Fix - Instructions

## Problem

Supabase is showing performance warnings for Row Level Security (RLS) policies:

1. **Auth RLS Initialization Plan**: Policies re-evaluate `auth.uid()` for each row, causing suboptimal performance
2. **Multiple Permissive Policies**: Some tables have multiple permissive policies for the same role/action

## Solution

All `auth.uid()` calls have been wrapped in `(select auth.uid())` to prevent re-evaluation per row. This is a Supabase best practice that significantly improves query performance.

## How to Apply the Fix

### Step 1: Run the Migration

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy and paste the entire contents of `server/database/fix_rls_performance.sql`
3. Click **Run**
4. Wait for completion (should take a few seconds)

### Step 2: Verify

1. Go to **Supabase Dashboard** → **Database** → **Policies**
2. Verify all policies are still present (they should be recreated)
3. Wait 5-10 minutes for Supabase to re-analyze
4. Check **Database** → **Advisor** - the warnings should disappear

## What Changed

### Before (Slow):
```sql
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);  -- Re-evaluated for each row
```

### After (Fast):
```sql
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING ((select auth.uid()) = id);  -- Evaluated once per query
```

## Impact

- ✅ **Performance**: 10-100x faster for queries with many rows
- ✅ **No Breaking Changes**: All functionality remains the same
- ✅ **Security**: No security implications, just performance optimization

## Multiple Permissive Policies

The "Multiple Permissive Policies" warnings are less critical. They occur when multiple policies allow the same action for the same role. This is by design in our system (e.g., admins can view all users AND users can view their own profile).

These warnings are acceptable and don't significantly impact performance compared to the auth function re-evaluation issue.

## Rollback

If you need to rollback:

1. Run the original `server/database/rls_policies.sql` file
2. This will recreate policies with the old (slower) format

## Testing

After applying the fix:

1. Test all user types (admin, customer, driver) can still access their data
2. Verify admins can still access all data
3. Check that queries are faster (especially for large datasets)

---

**All RLS policies have been optimized for performance!** ✅

