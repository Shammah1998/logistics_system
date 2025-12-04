import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import toast from 'react-hot-toast';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { signIn } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      await signIn(email, password);
      toast.success('Login successful');
      navigate('/place-order');
    } catch (error) {
      console.error('Login error:', error);
      toast.error(error?.message || 'Login failed. Please check your credentials.');
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
                Sign in to your account
              </h1>
              <p className="mt-3 text-sm text-slate-500">
                Access your deliveries, track drivers, and manage logistics in one place.
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
                    placeholder="you@company.com"
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

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full rounded-xl bg-primary py-3 text-sm font-semibold text-white shadow-lg shadow-primary/30 transition hover:bg-primary-dark focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:cursor-not-allowed disabled:bg-slate-300 disabled:shadow-none"
                >
                  {loading ? 'Signing in...' : 'Sign in'}
                </button>
              </form>

              <div className="mt-8 flex items-center justify-between text-sm text-slate-500">
                <span>Don't have an account?</span>
                <Link to="/signup" className="font-semibold text-primary hover:text-primary-dark">
                  Create account
                </Link>
              </div>
            </div>
          </div>
        </div>

        <div className="relative hidden bg-slate-900/95 lg:flex">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(37,99,235,0.35),_transparent_60%)]" />
          <div className="relative mx-auto flex w-full max-w-xl flex-col justify-between px-16 py-14 text-white">
            <div className="space-y-4">
              <p className="inline-flex rounded-full bg-white/10 px-4 py-1 text-xs font-semibold tracking-wider text-white/90 backdrop-blur">
                Logistics Platform
              </p>
              <h2 className="text-4xl font-semibold leading-snug">
                Manage deliveries, drivers, and customers from a single intelligent workspace.
              </h2>
              <p className="text-base text-white/70">
                Real-time tracking, automated PODs, and performance insights built for high-growth operations.
              </p>
            </div>

            <div className="rounded-2xl bg-white/10 p-6 backdrop-blur">
              <p className="text-sm text-white/70">Trusted by businesses across Kenya</p>
              <div className="mt-4 grid grid-cols-3 gap-4 text-center text-lg font-semibold">
                <div>
                  <p className="text-3xl font-bold text-white">450+</p>
                  <p className="text-xs text-white/70">Daily Jobs</p>
                </div>
                <div>
                  <p className="text-3xl font-bold text-white">120</p>
                  <p className="text-xs text-white/70">Drivers</p>
                </div>
                <div>
                  <p className="text-3xl font-bold text-white">98%</p>
                  <p className="text-xs text-white/70">On-time Rate</p>
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

