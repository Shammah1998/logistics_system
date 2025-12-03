# Troubleshooting Signup Error: "Database error saving new user"

## Quick Fix Steps

1. **Run the trigger SQL file** in Supabase SQL Editor:
   - Open `backend/database/trigger_create_user_record.sql`
   - Copy and paste into Supabase SQL Editor
   - Click Run

2. **Verify the trigger was created**:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
   ```

3. **Check if function exists**:
   ```sql
   SELECT proname FROM pg_proc WHERE proname = 'handle_new_user';
   ```

4. **Test the trigger manually** (optional):
   - Go to Supabase → Authentication → Users
   - Create a test user manually
   - Check if a record appears in the `users` table

## Common Issues

### Issue 1: Trigger not created
**Solution**: Run `trigger_create_user_record.sql` in Supabase SQL Editor

### Issue 2: RLS blocking insert
**Solution**: The function uses `SECURITY DEFINER` which should bypass RLS. If still failing, check Supabase logs.

### Issue 3: Phone field constraint
**Solution**: The trigger now handles empty phone by using 'N/A' as placeholder

### Issue 4: Function permissions
**Solution**: Ensure the function owner has INSERT permissions on users table

## Manual Workaround (Temporary)

If the trigger still doesn't work, you can manually create the user record:

1. Sign up through the frontend (this creates auth.users record)
2. Go to Supabase → Authentication → Users
3. Find the newly created user and copy their UUID
4. Run this SQL:
   ```sql
   INSERT INTO public.users (id, email, phone, user_type)
   VALUES (
       'USER_UUID_HERE'::UUID,
       'user@example.com',
       '+254712345678',
       'customer'::user_type_enum
   );
   ```

## Check Supabase Logs

1. Go to Supabase Dashboard → Logs → Postgres Logs
2. Look for errors related to `handle_new_user` function
3. Check for any constraint violations or permission errors

