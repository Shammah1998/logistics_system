import { createClient } from '@supabase/supabase-js';

// Lazy initialization - only create client when needed
let supabase = null;

function getSupabaseClient() {
  if (!supabase) {
    // Validate required environment variables
    const supabaseUrl = process.env.SUPABASE_URL;
    // Use SERVICE_ROLE_KEY for backend operations to bypass RLS
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !supabaseKey) {
      throw new Error(
        'Missing required environment variables: SUPABASE_URL and/or SUPABASE_SERVICE_ROLE_KEY. ' +
        'Please check your .env file.'
      );
    }

    supabase = createClient(supabaseUrl, supabaseKey);
  }
  return supabase;
}

export const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const { data: { user }, error } = await getSupabaseClient().auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }

    // Get user type from users table
    const { data: userData, error: userError } = await getSupabaseClient()
      .from('users')
      .select('user_type')
      .eq('id', user.id)
      .single();

    if (userError || !userData) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    req.user = {
      id: user.id,
      email: user.email,
      userType: userData.user_type
    };

    next();
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Authentication error'
    });
  }
};

export const requireUserType = (...allowedTypes) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!allowedTypes.includes(req.user.userType)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }

    next();
  };
};

