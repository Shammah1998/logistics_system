import { createContext, useContext, useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';
import { useNavigate } from 'react-router-dom';
import { getApiUrl } from '../config/api';

// Get environment variables
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Validate required environment variables (lazy check)
function validateEnvVars() {
  if (!supabaseUrl || !supabaseAnonKey) {
    const missingVars = [];
    if (!supabaseUrl) missingVars.push('VITE_SUPABASE_URL');
    if (!supabaseAnonKey) missingVars.push('VITE_SUPABASE_ANON_KEY');
    
    console.error('❌ Missing required environment variables:', missingVars.join(', '));
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
  }
}

// Create Supabase client - use default fetch, no custom wrappers
let supabase = null;
function getSupabaseClient() {
  validateEnvVars();
  if (!supabase) {
    console.log('🔧 Creating Supabase client with URL:', supabaseUrl);

    supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true, // keep admin sessions alive
        detectSessionInUrl: false,
        storage: typeof window !== 'undefined' ? window.localStorage : undefined,
        storageKey: 'sb-auth-token',
      }
    });
  }
  return supabase;
}

const AuthContext = createContext({});

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [userType, setUserType] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    let isMounted = true;
    let timeoutId;

    // Set a timeout to prevent infinite loading (10 seconds max)
    timeoutId = setTimeout(() => {
      if (isMounted && loading) {
        console.warn('⚠️ Auth initialization timeout - setting loading to false');
        setLoading(false);
      }
    }, 10000);

    const initAuth = async () => {
      try {
        const client = getSupabaseClient();
        console.log('📡 Calling getSession()...');
        const startTime = Date.now();
        const { data: { session }, error: sessionError } = await client.auth.getSession();
        console.log(`📡 getSession() completed in ${Date.now() - startTime}ms`);
        
        if (!isMounted) return;

        if (sessionError) {
          console.error('Session error:', sessionError);
          setUser(null);
          setUserType(null);
        } else if (session?.user) {
          setUser(session.user);
          // Fetch user type
          const { data, error } = await client
            .from('users')
            .select('user_type')
            .eq('id', session.user.id)
            .single();
          
          if (!isMounted) return;
          
          if (error) {
            console.error('Error fetching user type:', error);
            setUserType(null);
          } else {
            setUserType(data?.user_type);
          }
        } else {
          setUser(null);
          setUserType(null);
        }
      } catch (error) {
        console.error('Error initializing auth:', error);
        if (isMounted) {
          setUser(null);
          setUserType(null);
        }
      } finally {
        if (isMounted) {
          setLoading(false);
          clearTimeout(timeoutId);
        }
      }
    };

    initAuth();

    // Set up auth state change listener
    let subscription;
    try {
      const { data: { subscription: sub } } = getSupabaseClient().auth.onAuthStateChange(
        async (_event, session) => {
          if (!isMounted) return;
          
          if (session?.user) {
            setUser(session.user);
            const { data, error } = await getSupabaseClient()
              .from('users')
              .select('user_type')
              .eq('id', session.user.id)
              .single();
            
            if (!isMounted) return;
            setUserType(error ? null : data?.user_type);
          } else {
            setUser(null);
            setUserType(null);
          }
        }
      );
      subscription = sub;
    } catch (error) {
      console.error('Error setting up auth listener:', error);
    }

    return () => {
      isMounted = false;
      clearTimeout(timeoutId);
      subscription?.unsubscribe();
    };
  }, []);

  const signIn = async (email, password) => {
    console.log('🔐 Starting login for:', email);
    
    try {
      const client = getSupabaseClient();
      
      // Simple direct call - no timeout wrapper
      console.log('📡 Calling Supabase signInWithPassword...');
      const { data, error } = await client.auth.signInWithPassword({
        email,
        password,
      });
      
      console.log('📡 Supabase response received');
      
      if (error) {
        console.error('❌ Auth error:', error);
        throw error;
      }
      
      if (!data?.user) {
        throw new Error('Authentication failed - no user data returned');
      }
      
      console.log('✅ Auth successful, fetching user type...');
      
      // Fetch user type - try backend API first
      let userData = null;
      let userError = null;
      
      try {
        const apiUrl = getApiUrl();
        const response = await fetch(`${apiUrl}/auth/verify`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${data.session.access_token}`,
            'Content-Type': 'application/json'
          }
        });
        
        if (response.ok) {
          const verifyData = await response.json();
          if (verifyData.success && verifyData.data?.user?.userType) {
            userData = { user_type: verifyData.data.user.userType };
            console.log('✅ User type from backend API:', userData.user_type);
          }
        } else if (response.status === 401) {
          // 401 is expected in some cases (token not yet validated), silently fall through to Supabase query
          // Don't log as error - this is normal behavior
        } else {
          // Only log non-401 errors
          console.warn('⚠️ Backend API returned:', response.status);
        }
      } catch (apiError) {
        // Network errors are expected, don't log as warnings
        // Only log if it's a real issue
        if (apiError.name !== 'TypeError') {
          console.warn('⚠️ Backend API failed:', apiError.message);
        }
      }
      
      // Fallback to direct query
      if (!userData) {
        console.log('📡 Fetching user type from Supabase...');
        const { data: queryData, error: queryError } = await client
          .from('users')
          .select('user_type')
          .eq('id', data.user.id)
          .single();
        
        userData = queryData;
        userError = queryError;
      }
      
      if (userError) {
        console.error('❌ Error fetching user type:', userError);
        if (userError.code === 'PGRST116') {
          throw new Error('User account not found. Please contact support.');
        }
        throw new Error(`Failed to verify user: ${userError.message}`);
      }
      
      if (!userData?.user_type) {
        throw new Error('User account missing required information.');
      }
      
      console.log('✅ Login complete. User type:', userData.user_type);
      
      setUserType(userData.user_type);
      setUser(data.user);
      
      return { ...data, userType: userData.user_type };
    } catch (error) {
      console.error('❌ Login failed:', error);
      throw error;
    }
  };

  const signOut = async () => {
    const { error } = await getSupabaseClient().auth.signOut();
    if (error) throw error;
    setUser(null);
    setUserType(null);
    navigate('/login');
  };

  const value = {
    user,
    userType,
    loading,
    signIn,
    signOut,
    supabase: getSupabaseClient(),
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
