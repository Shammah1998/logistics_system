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

    // Create custom fetch with timeout for production
    const customFetch = (url, options = {}) => {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 8000); // 8 second timeout
      
      return fetch(url, {
        ...options,
        signal: controller.signal,
      }).finally(() => clearTimeout(timeoutId));
    };

    supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true, // keep admin sessions alive
        detectSessionInUrl: false,
        storage: typeof window !== 'undefined' ? window.localStorage : undefined,
        storageKey: 'sb-auth-token',
      },
      global: {
        fetch: customFetch,
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

    // Set a timeout to prevent infinite loading (3 seconds max - fail fast)
    timeoutId = setTimeout(() => {
      if (isMounted && loading) {
        console.warn('⚠️ Auth initialization timeout - setting loading to false');
        setLoading(false);
      }
    }, 3000);

    const initAuth = async () => {
      try {
        const client = getSupabaseClient();
        console.log('📡 Calling getSession()...');
        const startTime = Date.now();
        
        // Add timeout to getSession call (5 seconds max)
        const sessionPromise = client.auth.getSession();
        const timeoutPromise = new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Session check timeout')), 5000)
        );
        
        let sessionResult;
        try {
          sessionResult = await Promise.race([sessionPromise, timeoutPromise]);
        } catch (timeoutError) {
          console.warn('⚠️ Session check timed out, continuing without session');
          if (isMounted) {
            setUser(null);
            setUserType(null);
            setLoading(false);
            clearTimeout(timeoutId);
          }
          return;
        }
        
        const { data: { session }, error: sessionError } = sessionResult;
        console.log(`📡 getSession() completed in ${Date.now() - startTime}ms`);
        
        if (!isMounted) return;

        if (sessionError) {
          console.error('Session error:', sessionError);
          setUser(null);
          setUserType(null);
        } else if (session?.user) {
          setUser(session.user);
          // Fetch user type with timeout
          try {
            const userTypePromise = client
              .from('users')
              .select('user_type')
              .eq('id', session.user.id)
              .single();
            
            const userTypeTimeout = new Promise((_, reject) =>
              setTimeout(() => reject(new Error('User type fetch timeout')), 3000)
            );
            
            const { data, error } = await Promise.race([userTypePromise, userTypeTimeout]);
            
            if (!isMounted) return;
            
            if (error) {
              console.error('Error fetching user type:', error);
              setUserType(null);
            } else {
              setUserType(data?.user_type);
            }
          } catch (userTypeError) {
            console.warn('⚠️ User type fetch timed out, continuing without user type');
            setUserType(null);
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
      
      // Add timeout to signIn call (10 seconds max)
      console.log('📡 Calling Supabase signInWithPassword...');
      const signInPromise = client.auth.signInWithPassword({
        email,
        password,
      });
      
      const signInTimeout = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Login request timed out. Please check your internet connection and try again.')), 10000)
      );
      
      const { data, error } = await Promise.race([signInPromise, signInTimeout]);
      
      console.log('📡 Supabase response received');
      
      if (error) {
        console.error('❌ Auth error:', error);
        throw error;
      }
      
      if (!data?.user) {
        throw new Error('Authentication failed - no user data returned');
      }
      
      console.log('✅ Auth successful, fetching user type...');
      
      // Fetch user type - try backend API first with timeout
      let userData = null;
      let userError = null;
      
      try {
        const apiUrl = getApiUrl();
        const verifyPromise = fetch(`${apiUrl}/auth/verify`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${data.session.access_token}`,
            'Content-Type': 'application/json'
          }
        });
        
        const verifyTimeout = new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Verify timeout')), 5000)
        );
        
        const response = await Promise.race([verifyPromise, verifyTimeout]);
        
        if (response.ok) {
          const verifyData = await response.json();
          if (verifyData.success && verifyData.data?.user?.userType) {
            userData = { user_type: verifyData.data.user.userType };
            console.log('✅ User type from backend API:', userData.user_type);
          }
        } else if (response.status === 401) {
          // 401 is expected in some cases, silently fall through
        }
      } catch (apiError) {
        // Timeout or network error - fall through to Supabase query
        if (apiError.message !== 'Verify timeout') {
          console.warn('⚠️ Backend API failed:', apiError.message);
        }
      }
      
      // Fallback to direct query with timeout
      if (!userData) {
        console.log('📡 Fetching user type from Supabase...');
        const queryPromise = client
          .from('users')
          .select('user_type')
          .eq('id', data.user.id)
          .single();
        
        const queryTimeout = new Promise((_, reject) =>
          setTimeout(() => reject(new Error('User type query timeout')), 5000)
        );
        
        try {
          const { data: queryData, error: queryError } = await Promise.race([queryPromise, queryTimeout]);
          userData = queryData;
          userError = queryError;
        } catch (timeoutError) {
          throw new Error('Unable to verify user account. Please try again.');
        }
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
