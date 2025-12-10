import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';

const ProtectedRoute = ({ children, requireAdmin = false }) => {
  const { user, userType, loading, authReady } = useAuth();
  const [forceReady, setForceReady] = useState(false);

  // Emergency timeout: Force ready after 6 seconds if still loading
  useEffect(() => {
    const emergencyTimeout = setTimeout(() => {
      if (loading || !authReady) {
        console.warn('🚨 EMERGENCY: Forcing route to render after 6 seconds');
        setForceReady(true);
      }
    }, 6000);

    return () => clearTimeout(emergencyTimeout);
  }, [loading, authReady]);

  useEffect(() => {
    if (authReady && requireAdmin && user && userType !== 'admin') {
      toast.error('Access denied. Admin privileges required.');
    }
  }, [authReady, requireAdmin, user, userType]);

  // Show loading while auth is initializing (unless force ready)
  if ((loading || !authReady) && !forceReady) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontSize: '18px',
        backgroundColor: '#f8fafc'
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ 
            width: '40px', 
            height: '40px', 
            border: '4px solid #e2e8f0',
            borderTop: '4px solid #2563eb',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
            margin: '0 auto 16px'
          }}></div>
          <p>Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (requireAdmin && userType !== 'admin') {
    return <Navigate to="/login" replace />;
  }

  return children;
};

export default ProtectedRoute;

