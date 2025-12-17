import { createContext, useContext, useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';
import { useNavigate } from 'react-router-dom';

// Get environment variables
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Get customer panel URL - use environment variable in production, fallback to current origin in development
const getCustomerPanelUrl = () => {
  // In production, use the environment variable
  if (import.meta.env.VITE_CUSTOMER_PANEL_URL) {
    return import.meta.env.VITE_CUSTOMER_PANEL_URL;
  }
  // In development, use current origin
  if (typeof window !== 'undefined') {
    return window.location.origin;
  }
  return '';
};

// Validate required environment variables (lazy check)
function validateEnvVars() {
  if (!supabaseUrl || !supabaseAnonKey) {
    const missingVars = [];
    if (!supabaseUrl) missingVars.push('VITE_SUPABASE_URL');
    if (!supabaseAnonKey) missingVars.push('VITE_SUPABASE_ANON_KEY');
    
    console.error('❌ Missing required environment variables:', missingVars.join(', '));
    console.error('Please create a .env file in the customer-panel directory with all required variables.');
    console.error('See .env.example for reference.');
    console.error('⚠️ IMPORTANT: If you just created/updated .env, restart the dev server (npm run dev)');
    
    // Show user-friendly error in development
    if (import.meta.env.DEV) {
      document.body.innerHTML = `
        <div style="display: flex; align-items: center; justify-content: center; height: 100vh; font-family: system-ui;">
          <div style="text-align: center; padding: 2rem; border: 2px solid #ef4444; border-radius: 8px; max-width: 500px;">
            <h1 style="color: #ef4444; margin-bottom: 1rem;">Configuration Error</h1>
            <p style="margin-bottom: 1rem;">Missing required environment variables:</p>
            <ul style="text-align: left; display: inline-block; margin-bottom: 1rem;">
              ${missingVars.map(v => `<li><code>${v}</code></li>`).join('')}
            </ul>
            <p>Please create a <code>.env</code> file in the customer-panel directory.</p>
            <p>See <code>.env.example</code> for reference.</p>
            <p style="margin-top: 1rem; color: #f59e0b; font-weight: bold;">
              ⚠️ If you just created/updated .env, restart the dev server!
            </p>
          </div>
        </div>
      `;
    }
    
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
  }
}

// Create Supabase client (will validate when used)
let supabase = null;
function getSupabaseClient() {
  validateEnvVars();
  if (!supabase) {
    supabase = createClient(supabaseUrl, supabaseAnonKey);
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
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    // Check active session
    getSupabaseClient().auth.getSession()
      .then(({ data: { session } }) => {
        setUser(session?.user ?? null);
        setLoading(false);
      })
      .catch((error) => {
        console.error('Auth session error:', error);
        setUser(null);
        setLoading(false);
      });

    // Listen for auth changes
    let subscription;
    try {
      const {
        data: { subscription: sub },
      } = getSupabaseClient().auth.onAuthStateChange((_event, session) => {
        setUser(session?.user ?? null);
      });
      subscription = sub;
    } catch (error) {
      console.error('Error setting up auth listener:', error);
    }

    return () => {
      if (subscription) {
        subscription.unsubscribe();
      }
    };
  }, []);

  const signIn = async (email, password) => {
    const { data, error } = await getSupabaseClient().auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    return data;
  };

  const signUp = async ({ email, password, fullName, phone }) => {
    // Get the correct panel URL (production or development)
    const panelUrl = getCustomerPanelUrl();
    const redirectTo = `${panelUrl}/login`;

    console.log('📧 Email confirmation will redirect to:', redirectTo);

    const { data, error } = await getSupabaseClient().auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: redirectTo,
        data: {
          full_name: fullName,
          phone,
        },
      },
    });
    if (error) throw error;
    return data;
  };

  const signOut = async () => {
    const { error } = await getSupabaseClient().auth.signOut();
    if (error) throw error;
    navigate('/login');
  };

  const value = {
    user,
    loading,
    signIn,
    signUp,
    signOut,
    supabase: getSupabaseClient(),
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
