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

// Use service role key for admin operations
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// Get admin details from command line arguments
const args = process.argv.slice(2);
const email = args.find(arg => arg.startsWith('email='))?.split('=')[1];
const password = args.find(arg => arg.startsWith('password='))?.split('=')[1];
const fullName = args.find(arg => arg.startsWith('name='))?.split('=')[1] || 'Admin User';
const phone = args.find(arg => arg.startsWith('phone='))?.split('=')[1] || 'N/A';

if (!email || !password) {
  console.error('❌ Usage: node scripts/create-admin.js email=admin@example.com password=SecurePass123 name="Admin Name" phone=+254712345678');
  console.error('\nRequired:');
  console.error('  email=admin@example.com');
  console.error('  password=SecurePass123');
  console.error('\nOptional:');
  console.error('  name="Admin Name"');
  console.error('  phone=+254712345678');
  process.exit(1);
}

async function createAdmin() {
  try {
    console.log('Creating admin user...');
    console.log(`Email: ${email}`);
    console.log(`Name: ${fullName}`);
    console.log(`Phone: ${phone}`);
    
    // Step 1: Create user in Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        full_name: fullName,
        phone: phone
      }
    });

    if (authError) {
      if (authError.message.includes('already registered')) {
        console.log('⚠️  User already exists in auth.users, updating to admin...');
        
        // Get existing user
        const { data: existingUser } = await supabase.auth.admin.getUserByEmail(email);
        if (!existingUser?.user) {
          console.error('❌ Could not find existing user');
          process.exit(1);
        }
        
        // Step 2: Create/Update record in public.users with admin type
        const { error: userError } = await supabase
          .from('users')
          .upsert({
            id: existingUser.user.id,
            email: existingUser.user.email,
            phone: phone,
            user_type: 'admin'
          }, {
            onConflict: 'id'
          });

        if (userError) {
          console.error('❌ Error updating user record:', userError.message);
          process.exit(1);
        }

        console.log('✅ Admin user updated successfully!');
        console.log(`User ID: ${existingUser.user.id}`);
        console.log(`Email: ${email}`);
        console.log(`User Type: admin`);
        return;
      }
      
      console.error('❌ Error creating user:', authError.message);
      process.exit(1);
    }

    if (!authData?.user) {
      console.error('❌ Failed to create user');
      process.exit(1);
    }

    console.log('✅ User created in auth.users');

    // Step 2: Create record in public.users with admin type
    const { error: userError } = await supabase
      .from('users')
      .upsert({
        id: authData.user.id,
        email: authData.user.email,
        phone: phone,
        user_type: 'admin'
      }, {
        onConflict: 'id'
      });

    if (userError) {
      console.error('❌ Error creating user record:', userError.message);
      console.error('⚠️  User was created in auth.users but not in public.users');
      console.error('   You may need to run the fix_missing_users.sql script');
      process.exit(1);
    }

    console.log('✅ Admin user created successfully!');
    console.log(`User ID: ${authData.user.id}`);
    console.log(`Email: ${email}`);
    console.log(`Password: ${password}`);
    console.log(`User Type: admin`);
    console.log('\nYou can now log in to the admin panel with these credentials.');

  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
    process.exit(1);
  }
}

createAdmin();

