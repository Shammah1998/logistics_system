import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { getApiUrl } from '../config/api';

const OrdersList = () => {
  const { supabase } = useAuth();
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [expandedRows, setExpandedRows] = useState(new Set());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    try {
      setLoading(true);
      const token = (await supabase.auth.getSession()).data.session?.access_token;
      
      const response = await fetch(`${getApiUrl()}/orders/my/orders`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      const data = await response.json();
      
      if (data.success) {
        setOrders(data.data || []);
      } else {
        console.error('Failed to fetch orders:', data.message);
      }
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const toggleRow = (orderId) => {
    const newExpanded = new Set(expandedRows);
    if (newExpanded.has(orderId)) {
      newExpanded.delete(orderId);
    } else {
      newExpanded.add(orderId);
    }
    setExpandedRows(newExpanded);
  };

  const getStatusColor = (status) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      assigned: 'bg-blue-100 text-blue-800',
      in_transit: 'bg-purple-100 text-purple-800',
      delivered: 'bg-green-100 text-green-800',
      cancelled: 'bg-red-100 text-red-800',
    };
    return colors[status] || 'bg-slate-100 text-slate-800';
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  };

  const formatCurrency = (amount) => {
    return `Ksh ${amount?.toLocaleString() || '0'}`;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Orders</h1>
          <p className="mt-2 text-sm text-slate-600">
            View and manage all your orders
          </p>
        </div>
        <button 
          onClick={fetchOrders}
          className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50"
        >
          Refresh
        </button>
      </div>

      {/* Orders Table */}
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Order ID
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Status
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Date
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Amount
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Pickup
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Drops
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 bg-white">
              {orders.length === 0 ? (
                <tr>
                  <td colSpan="7" className="px-6 py-12 text-center">
                    <svg
                      className="mx-auto h-12 w-12 text-slate-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                      />
                    </svg>
                    <h3 className="mt-2 text-sm font-medium text-slate-900">No orders</h3>
                    <p className="mt-1 text-sm text-slate-500">Get started by placing a new order.</p>
                    <div className="mt-6">
                      <button
                        onClick={() => navigate('/place-order')}
                        className="rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-primary/30 transition hover:bg-primary-dark"
                      >
                        Place New Order
                      </button>
                    </div>
                  </td>
                </tr>
              ) : (
                orders.map((order) => {
                  const isExpanded = expandedRows.has(order.id);
                  const firstDrop = order.drops?.[0];
                  const lastDrop = order.drops?.[order.drops?.length - 1];

                  return (
                    <>
                      <tr
                        key={order.id}
                        className="cursor-pointer transition hover:bg-slate-50"
                        onClick={() => toggleRow(order.id)}
                      >
                        <td className="whitespace-nowrap px-6 py-4 text-sm font-medium text-slate-900">
                          {order.order_number || order.id.slice(0, 8)}
                        </td>
                        <td className="whitespace-nowrap px-6 py-4">
                          <span
                            className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${getStatusColor(
                              order.status
                            )}`}
                          >
                            {order.status?.replace('_', ' ').toUpperCase() || 'PENDING'}
                          </span>
                        </td>
                        <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                          {formatDate(order.created_at)}
                        </td>
                        <td className="whitespace-nowrap px-6 py-4 text-sm font-semibold text-slate-900">
                          {formatCurrency(order.total_amount)}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-600 max-w-xs truncate">
                          {order.pickup_address || 'N/A'}
                        </td>
                        <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                          {order.drops?.length || 0} drop{order.drops?.length !== 1 ? 's' : ''}
                        </td>
                        <td className="whitespace-nowrap px-6 py-4 text-sm">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              navigate(`/orders/${order.id}`);
                            }}
                            className="text-primary hover:text-primary-dark font-medium"
                          >
                            Track
                          </button>
                        </td>
                      </tr>
                      {isExpanded && (
                        <tr>
                          <td colSpan="7" className="bg-slate-50 px-6 py-6">
                            <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                              {/* Left Column - Order Details */}
                              <div className="space-y-4">
                                <h3 className="text-lg font-semibold text-slate-900">Order Summary</h3>
                                <div className="space-y-3 rounded-xl border border-slate-200 bg-white p-4">
                                  <div className="flex justify-between">
                                    <span className="text-sm text-slate-600">Amount:</span>
                                    <span className="text-sm font-semibold text-slate-900">
                                      {formatCurrency(order.total_amount)}
                                    </span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span className="text-sm text-slate-600">Status:</span>
                                    <span
                                      className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${getStatusColor(
                                        order.status
                                      )}`}
                                    >
                                      {order.status?.replace('_', ' ').toUpperCase()}
                                    </span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span className="text-sm text-slate-600">Distance:</span>
                                    <span className="text-sm font-semibold text-slate-900">
                                      {order.total_distance ? `${order.total_distance} km` : 'N/A'}
                                    </span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span className="text-sm text-slate-600">Drops:</span>
                                    <span className="text-sm font-semibold text-slate-900">
                                      {order.drops?.length || 0}
                                    </span>
                                  </div>
                                  {order.pickup_address && (
                                    <div className="pt-3 border-t border-slate-200">
                                      <p className="text-sm font-medium text-slate-900 mb-2">Pickup Location:</p>
                                      <p className="text-sm text-slate-600">{order.pickup_address}</p>
                                    </div>
                                  )}
                                </div>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    navigate(`/orders/${order.id}`);
                                  }}
                                  className="w-full rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-primary/30 transition hover:bg-primary-dark"
                                >
                                  View Full Details
                                </button>
                              </div>

                              {/* Right Column - Drop Locations */}
                              <div>
                                <h3 className="text-lg font-semibold text-slate-900 mb-4">Drop Locations</h3>
                                <div className="space-y-2">
                                  {order.drops?.map((drop, index) => (
                                    <div key={drop.id} className="rounded-xl border border-slate-200 bg-white p-3">
                                      <div className="flex items-start gap-3">
                                        <span className="flex-shrink-0 w-6 h-6 bg-primary/10 text-primary rounded-full flex items-center justify-center text-xs font-semibold">
                                          {index + 1}
                                        </span>
                                        <div>
                                          <p className="text-sm font-medium text-slate-900">{drop.recipient_name}</p>
                                          <p className="text-xs text-slate-600">{drop.address}</p>
                                          {drop.phone && (
                                            <p className="text-xs text-slate-400">{drop.phone}</p>
                                          )}
                                        </div>
                                      </div>
                                    </div>
                                  )) || <p className="text-slate-500 text-sm">No drop locations</p>}
                                </div>
                              </div>
                            </div>
                          </td>
                        </tr>
                      )}
                    </>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default OrdersList;
