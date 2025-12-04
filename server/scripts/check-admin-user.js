import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceRoleKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}

// Use service role key for admin operations (bypasses RLS)
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// Get email from command line
const email = process.argv[2];

if (!email) {
  console.error('❌ Usage: node scripts/check-admin-user.js <email>');
  console.error('Example: node scripts/check-admin-user.js admin@example.com');
  process.exit(1);
}

async function checkAdminUser() {
  try {
    console.log(`\n🔍 Checking admin user: ${email}\n`);
    
    // Step 1: Check if user exists in auth.users
    console.log('1️⃣ Checking auth.users...');
    const { data: authUser, error: authError } = await supabase.auth.admin.getUserByEmail(email);
    
    if (authError) {
      console.error('❌ Error fetching user from auth.users:', authError.message);
      process.exit(1);
    }
    
    if (!authUser?.user) {
      console.error('❌ User not found in auth.users');
      console.log('\n💡 Solution: Create the user first using:');
      console.log(`   node scripts/create-admin.js email=${email} password=YourPassword`);
      process.exit(1);
    }
    
    console.log('✅ User found in auth.users');
    console.log(`   User ID: ${authUser.user.id}`);
    console.log(`   Email: ${authUser.user.email}`);
    console.log(`   Email Confirmed: ${authUser.user.email_confirmed_at ? 'Yes' : 'No'}`);
    
    // Step 2: Check if user exists in public.users
    console.log('\n2️⃣ Checking public.users...');
    const { data: publicUser, error: publicError } = await supabase
      .from('users')
      .select('*')
      .eq('id', authUser.user.id)
      .single();
    
    if (publicError) {
      if (publicError.code === 'PGRST116') {
        console.error('❌ User NOT found in public.users table');
        console.log('\n💡 Solution: Run the fix_missing_users.sql script or create the user record:');
        console.log(`   node scripts/create-admin.js email=${email} password=YourPassword`);
        process.exit(1);
      } else {
        console.error('❌ Error fetching user from public.users:', publicError.message);
        process.exit(1);
      }
    }
    
    if (!publicUser) {
      console.error('❌ User record not found in public.users');
      process.exit(1);
    }
    
    console.log('✅ User found in public.users');
    console.log(`   User ID: ${publicUser.id}`);
    console.log(`   Email: ${publicUser.email}`);
    console.log(`   Phone: ${publicUser.phone}`);
    console.log(`   User Type: ${publicUser.user_type}`);
    
    // Step 3: Check user_type
    console.log('\n3️⃣ Checking user_type...');
    if (publicUser.user_type !== 'admin') {
      console.error(`❌ User type is '${publicUser.user_type}', not 'admin'`);
      console.log('\n💡 Solution: Update user_type to admin:');
      console.log(`   node scripts/create-admin.js email=${email} password=YourPassword`);
      process.exit(1);
    }
    
    console.log('✅ User type is correct: admin');
    
    // Step 4: Test RLS policies (using anon key to simulate frontend)
    console.log('\n4️⃣ Testing RLS policies...');
    const supabaseAnon = createClient(
      supabaseUrl,
      process.env.SUPABASE_ANON_KEY || 'test',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    );
    
    // This would require a valid session token, so we'll just note it
    console.log('⚠️  RLS test requires active session (test manually in frontend)');
    
    // Summary
    console.log('\n✅ SUMMARY: Admin user is properly configured!');
    console.log(`\n📋 User Details:`);
    console.log(`   Email: ${email}`);
    console.log(`   User ID: ${authUser.user.id}`);
    console.log(`   User Type: ${publicUser.user_type}`);
    console.log(`   Email Confirmed: ${authUser.user.email_confirmed_at ? 'Yes' : 'No'}`);
    
    if (!authUser.user.email_confirmed_at) {
      console.log('\n⚠️  WARNING: Email is not confirmed. This might prevent login.');
      console.log('   The create-admin.js script should auto-confirm emails.');
    }
    
    console.log('\n✅ You should be able to log in to the admin panel now!');
    
  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

checkAdminUser();



