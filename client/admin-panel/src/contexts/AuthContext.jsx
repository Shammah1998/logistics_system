import { createContext, useContext, useState, useEffect, useRef } from 'react';
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

// Create Supabase client - SIMPLE, no custom fetch or timeouts
let supabase = null;
function getSupabaseClient() {
  validateEnvVars();
  if (!supabase) {
    console.log('🔧 Creating Supabase client with URL:', supabaseUrl);
    
    supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: false,
        storage: typeof window !== 'undefined' ? window.localStorage : undefined,
        storageKey: 'sb-admin-auth-token', // Unique key for admin panel
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
  const [authReady, setAuthReady] = useState(false);
  const navigate = useNavigate();
  const initRef = useRef(false);

  // Initialize auth on mount
  useEffect(() => {
    // Prevent double initialization in React Strict Mode
    if (initRef.current) return;
    initRef.current = true;

    let isMounted = true;
    let authStateChangeHandled = false;

    const initAuth = async () => {
      console.log('📡 Initializing auth...');
      
      try {
        const client = getSupabaseClient();
        
        // Get current session - no timeout, let it complete naturally
        const { data: { session }, error } = await client.auth.getSession();
        
        if (!isMounted) return;

        if (error) {
          console.error('Session error:', error.message);
          setUser(null);
          setUserType(null);
        } else if (session?.user) {
          console.log('📡 Found existing session for:', session.user.email);
          setUser(session.user);
          
          // Fetch user type
          try {
            const { data: userData, error: userError } = await client
              .from('users')
              .select('user_type')
              .eq('id', session.user.id)
              .single();
            
            if (isMounted) {
              if (userError) {
                console.error('Error fetching user type:', userError.message);
                setUserType(null);
              } else {
                setUserType(userData?.user_type || null);
              }
            }
          } catch (err) {
            console.error('Error in user type fetch:', err.message);
            if (isMounted) {
              setUserType(null);
            }
          }
        } else {
          console.log('📡 No existing session');
          setUser(null);
          setUserType(null);
        }
      } catch (err) {
        console.error('Auth init error:', err.message);
        if (isMounted) {
          setUser(null);
          setUserType(null);
        }
      } finally {
        // Only set ready if auth state change hasn't already handled it
        if (isMounted && !authStateChangeHandled) {
          setLoading(false);
          setAuthReady(true);
          console.log('✅ Auth initialization complete');
        }
      }
    };

    // Set up auth state change listener FIRST (before initAuth)
    // This ensures we catch SIGNED_IN events immediately
    const { data: { subscription } } = getSupabaseClient().auth.onAuthStateChange(
      async (event, session) => {
        console.log('🔄 Auth state changed:', event);
        
        if (!isMounted) return;
        authStateChangeHandled = true;
        
        if (session?.user) {
          setUser(session.user);
          
          // Fetch user type on auth change
          try {
            const { data: userData, error: userError } = await getSupabaseClient()
              .from('users')
              .select('user_type')
              .eq('id', session.user.id)
              .single();
            
            if (isMounted) {
              if (userError) {
                console.error('Error fetching user type in auth change:', userError.message);
                setUserType(null);
              } else {
                setUserType(userData?.user_type || null);
              }
              // Always clear loading states when auth state changes
              setLoading(false);
              setAuthReady(true);
            }
          } catch (err) {
            console.error('Error in auth state change handler:', err.message);
            if (isMounted) {
              setUserType(null);
              setLoading(false);
              setAuthReady(true);
            }
          }
        } else {
          setUser(null);
          setUserType(null);
          if (isMounted) {
            setLoading(false);
            setAuthReady(true);
          }
        }
      }
    );

    // Start auth initialization AFTER setting up listener
    initAuth();

    return () => {
      isMounted = false;
      subscription?.unsubscribe();
    };
  }, []);

  // Sign in function - simple and direct
  const signIn = async (email, password) => {
    console.log('🔐 Starting login for:', email);
    
      const client = getSupabaseClient();
      
    // Direct Supabase call - no wrappers, no timeouts
      console.log('📡 Calling Supabase signInWithPassword...');
      const { data, error } = await client.auth.signInWithPassword({
        email,
        password,
      });
      
      console.log('📡 Supabase response received');
      
      if (error) {
      console.error('❌ Auth error:', error.message);
        throw error;
      }
      
      if (!data?.user) {
        throw new Error('Authentication failed - no user data returned');
      }
      
      console.log('✅ Auth successful, fetching user type...');
      
      // Fetch user type - try backend API first
      let userData = null;
      
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
        }
      } catch (apiError) {
      console.warn('⚠️ Backend API verify failed, using Supabase fallback');
      }
      
    // Fallback to direct Supabase query
      if (!userData) {
        console.log('📡 Fetching user type from Supabase...');
        const { data: queryData, error: queryError } = await client
          .from('users')
          .select('user_type')
          .eq('id', data.user.id)
          .single();
        
      if (queryError) {
        console.error('❌ Error fetching user type:', queryError.message);
        if (queryError.code === 'PGRST116') {
          throw new Error('User account not found. Please contact support.');
        }
        throw new Error(`Failed to verify user: ${queryError.message}`);
      }
      
      userData = queryData;
      }
      
      if (!userData?.user_type) {
        throw new Error('User account missing required information.');
      }
      
      console.log('✅ Login complete. User type:', userData.user_type);
      
      setUserType(userData.user_type);
      setUser(data.user);
      
      return { ...data, userType: userData.user_type };
  };

  const signOut = async () => {
    try {
      await getSupabaseClient().auth.signOut();
    } catch (err) {
      console.error('Sign out error:', err.message);
    }
    setUser(null);
    setUserType(null);
    navigate('/login');
  };

  const value = {
    user,
    userType,
    loading,
    authReady,
    signIn,
    signOut,
    supabase: getSupabaseClient(),
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
