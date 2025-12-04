import { Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import ErrorBoundary from './components/ErrorBoundary';
import Layout from './components/Layout';
import Login from './pages/Login';
import Signup from './pages/Signup';
import OrdersList from './pages/OrdersList';
import OrderTracking from './pages/OrderTracking';
import PlaceOrder from './pages/PlaceOrder';

function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <Toaster position="top-right" />
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<PlaceOrder />} />
            <Route path="place-order" element={<PlaceOrder />} />
            <Route path="orders" element={<OrdersList />} />
            <Route path="orders/:orderId" element={<OrderTracking />} />
            <Route path="place-order" element={<PlaceOrder />} />
          </Route>
        </Routes>
      </AuthProvider>
    </ErrorBoundary>
  );
}

export default App;

