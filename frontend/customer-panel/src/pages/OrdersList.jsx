import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const OrdersList = () => {
  const { supabase } = useAuth();
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [expandedRows, setExpandedRows] = useState(new Set());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return;

        const { data, error } = await supabase
          .from('orders')
          .select('*, drops(*)')
          .eq('customer_id', user.id)
          .order('created_at', { ascending: false });

        if (error) throw error;
        setOrders(data || []);
      } catch (error) {
        console.error('Error fetching orders:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchOrders();
  }, [supabase]);

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
        <button className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50">
          Download CSV
        </button>
      </div>

      {/* Orders Table */}
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  Transaction ID
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
                  From
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider text-slate-700">
                  To
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
                        <td className="px-6 py-4 text-sm text-slate-600">
                          {firstDrop?.pickup_address || 'N/A'}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-600">
                          {lastDrop?.delivery_address || 'N/A'}
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
                                  {firstDrop && (
                                    <>
                                      <div className="pt-3 border-t border-slate-200">
                                        <p className="text-sm font-medium text-slate-900 mb-2">Pickup Location:</p>
                                        <p className="text-sm text-slate-600">{firstDrop.pickup_address}</p>
                                      </div>
                                      <div>
                                        <p className="text-sm font-medium text-slate-900 mb-2">Delivery Location:</p>
                                        <p className="text-sm text-slate-600">{lastDrop?.delivery_address}</p>
                                      </div>
                                    </>
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

                              {/* Right Column - Driver Info (if assigned) */}
                              <div>
                                {order.driver_id ? (
                                  <div>
                                    <h3 className="text-lg font-semibold text-slate-900 mb-4">Driver Information</h3>
                                    <div className="rounded-xl border border-slate-200 bg-white p-4">
                                      <div className="flex items-center space-x-4">
                                        <div className="h-16 w-16 rounded-full bg-slate-200 flex items-center justify-center">
                                          <svg className="h-8 w-8 text-slate-400" fill="currentColor" viewBox="0 0 20 20">
                                            <path fillRule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clipRule="evenodd" />
                                          </svg>
                                        </div>
                                        <div>
                                          <p className="text-sm font-medium text-slate-900">Driver Assigned</p>
                                          <p className="text-sm text-slate-600">Contact driver for updates</p>
                                        </div>
                                      </div>
                                    </div>
                                  </div>
                                ) : (
                                  <div className="rounded-xl border border-slate-200 bg-white p-4">
                                    <p className="text-sm text-slate-600">No driver assigned yet</p>
                                  </div>
                                )}
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
