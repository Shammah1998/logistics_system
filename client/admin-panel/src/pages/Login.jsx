import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import toast from 'react-hot-toast';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [testStatus, setTestStatus] = useState('');
  const [loginError, setLoginError] = useState('');
  const { signIn, signOut, loading: authLoading, authReady } = useAuth();
  const navigate = useNavigate();

  // Test Supabase connection directly
  const testConnection = async () => {
    setTestStatus('Testing REST API...');
    try {
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      
      console.log('🔍 Testing connection to:', supabaseUrl);
      
      // Test REST API
      const startTime = Date.now();
      const response = await fetch(`${supabaseUrl}/rest/v1/`, {
        method: 'GET',
        headers: {
          'apikey': supabaseKey,
          'Content-Type': 'application/json'
        }
      });
      const restElapsed = Date.now() - startTime;
      
      if (!response.ok) {
        setTestStatus(`❌ REST API Error: ${response.status}`);
        return;
      }
      
      console.log(`✅ REST API: ${restElapsed}ms`);
      setTestStatus(`REST: ${restElapsed}ms. Testing Auth...`);
      
      // Test Auth API
      const authStart = Date.now();
      const authResponse = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
        method: 'POST',
        headers: {
          'apikey': supabaseKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email: 'test@test.com',
          password: 'testpassword'
        })
      });
      const authElapsed = Date.now() - authStart;
      
      console.log(`✅ Auth API response in ${authElapsed}ms:`, authResponse.status);
      setTestStatus(`✅ REST: ${restElapsed}ms, Auth: ${authElapsed}ms (${authResponse.status})`);
      
    } catch (error) {
      setTestStatus(`❌ Error: ${error.message}`);
      console.error('❌ Connection test error:', error);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setLoginError('');

    try {
      console.log('🚀 Login attempt started for:', email);
      const result = await signIn(email, password);
      
      // Verify admin status before navigating
      if (!result.userType || result.userType !== 'admin') {
        console.warn('⚠️ Login successful but user is not admin:', result.userType);
        toast.error('Access denied. Admin privileges required.');
        setLoginError('Access denied. Admin privileges required.');
        // Sign out the user since they're not an admin
        await signOut();
        return;
      }
      
      console.log('✅ Admin login successful, navigating to dashboard...');
      toast.success('Login successful');
      navigate('/dashboard');
    } catch (error) {
      console.error('❌ Login error:', error);
      const errorMessage = error.message || 'Login failed. Please check your credentials.';
      
      // Provide more specific error messages
      let displayError;
      if (errorMessage.includes('Invalid login credentials')) {
        displayError = 'Invalid email or password. Please check your credentials.';
      } else if (errorMessage.includes('fetch') || errorMessage.includes('network')) {
        displayError = 'Network error. Please check your internet connection.';
      } else {
        displayError = errorMessage;
      }
      
      setLoginError(displayError);
      toast.error(displayError);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 lg:bg-white">
      <div className="grid min-h-screen lg:grid-cols-2">
        <div className="flex flex-col justify-center px-6 py-12 sm:px-12 lg:px-24">
          <div className="mx-auto w-full max-w-md">
            <div className="mb-8">
              <p className="text-sm font-medium text-primary">Welcome back</p>
              <h1 className="mt-2 text-3xl font-bold text-slate-900">
                Admin Sign In
              </h1>
              <p className="mt-3 text-sm text-slate-500">
                Access the admin dashboard to manage orders, drivers, and customers.
              </p>
            </div>

            <div className="rounded-2xl border border-slate-100 bg-white p-8 shadow-lg shadow-slate-100/60">
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700">Email address</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-900 outline-none transition focus:border-primary focus:bg-white focus:shadow-[0_0_0_3px_rgba(37,99,235,0.1)]"
                    placeholder="admin@company.com"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700">Password</label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-900 outline-none transition focus:border-primary focus:bg-white focus:shadow-[0_0_0_3px_rgba(37,99,235,0.1)]"
                    placeholder="Enter your password"
                  />
                </div>

                {loginError && (
                  <div className="rounded-lg bg-red-50 border border-red-200 p-3 text-sm text-red-700">
                    {loginError}
                  </div>
                )}

                <button
                  type="submit"
                  disabled={loading || !authReady}
                  className="w-full rounded-xl bg-primary py-3 text-sm font-semibold text-white shadow-lg shadow-primary/30 transition hover:bg-primary-dark focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:cursor-not-allowed disabled:bg-slate-300 disabled:shadow-none"
                >
                  {!authReady ? 'Initializing...' : loading ? 'Signing in...' : 'Sign in'}
                </button>
              </form>
              
              {/* Debug: Test connection button */}
              <div className="mt-4 pt-4 border-t border-slate-200">
                <button
                  type="button"
                  onClick={testConnection}
                  className="w-full rounded-xl bg-slate-100 py-2 text-xs font-medium text-slate-600 hover:bg-slate-200 transition"
                >
                  Test Supabase Connection
                </button>
                {testStatus && (
                  <p className="mt-2 text-xs text-center text-slate-500">{testStatus}</p>
                )}
              </div>
            </div>
          </div>
        </div>

        <div className="relative hidden bg-slate-900/95 lg:flex">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(37,99,235,0.35),_transparent_60%)]" />
          <div className="relative mx-auto flex w-full max-w-xl flex-col justify-between px-16 py-14 text-white">
            <div className="space-y-4">
              <p className="inline-flex rounded-full bg-white/10 px-4 py-1 text-xs font-semibold tracking-wider text-white/90 backdrop-blur">
                Admin Dashboard
              </p>
              <h2 className="text-4xl font-semibold leading-snug">
                Manage your logistics operations with powerful admin tools.
              </h2>
              <p className="text-base text-white/70">
                Monitor orders, manage drivers, track performance, and optimize your delivery network from a single dashboard.
              </p>
            </div>

            <div className="rounded-2xl bg-white/10 p-6 backdrop-blur">
              <p className="text-sm text-white/70">Platform Overview</p>
              <div className="mt-4 grid grid-cols-3 gap-4 text-center text-lg font-semibold">
                <div>
                  <p className="text-3xl font-bold text-white">450+</p>
                  <p className="text-xs text-white/70">Daily Orders</p>
                </div>
                <div>
                  <p className="text-3xl font-bold text-white">120</p>
                  <p className="text-xs text-white/70">Active Drivers</p>
                </div>
                <div>
                  <p className="text-3xl font-bold text-white">98%</p>
                  <p className="text-xs text-white/70">Success Rate</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
