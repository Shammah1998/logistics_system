import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { getApiUrl } from '../config/api';

const OrderTracking = () => {
  const { orderId } = useParams();
  const { supabase } = useAuth();
  const navigate = useNavigate();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchOrder = async () => {
      try {
        const token = (await supabase.auth.getSession()).data.session?.access_token;
        if (!token) {
          navigate('/login');
          return;
        }

        const response = await fetch(`${getApiUrl()}/orders/${orderId}`, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });

        const data = await response.json();

        if (data.success && data.data) {
          // Backend API returns formatted order data
          const orderData = data.data;
          setOrder({
            ...orderData,
            // Ensure all expected fields are present
            order_number: orderData.order_number || orderData.orderNumber,
            total_amount: orderData.total_amount || orderData.totalAmount,
            created_at: orderData.created_at || orderData.createdAt,
            assigned_at: orderData.assigned_at || orderData.assignedAt,
            picked_up_at: orderData.picked_up_at || orderData.pickedUpAt,
            delivered_at: orderData.delivered_at || orderData.deliveredAt,
            drops: orderData.drops || [],
            drivers: orderData.driver ? [orderData.driver] : []
          });
        } else {
          console.error('Error fetching order:', data.message || 'Order not found');
          setOrder(null);
        }
      } catch (error) {
        console.error('Error fetching order:', error);
      } finally {
        setLoading(false);
      }
    };

    if (orderId) {
      fetchOrder();
    }
  }, [orderId, supabase, navigate]);

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const formatCurrency = (amount) => {
    return `Ksh ${amount?.toLocaleString() || '0'}`;
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

  const timelineEvents = [
    { status: 'pending', label: 'Order Created', date: order?.created_at },
    { status: 'assigned', label: 'Order Assigned', date: order?.assigned_at },
    { status: 'in_transit', label: 'In Transit', date: order?.picked_up_at },
    { status: 'delivered', label: 'Delivered', date: order?.delivered_at },
  ].filter((event) => {
    if (event.status === 'pending') return true;
    return event.date;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="text-center py-12">
        <p className="text-slate-600">Order not found</p>
        <button
          onClick={() => navigate('/orders')}
          className="mt-4 rounded-xl bg-primary px-4 py-2 text-sm font-semibold text-white"
        >
          Back to Orders
        </button>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
      {/* Left Panel - Order Details & Timeline */}
      <div className="space-y-6">
        {/* Order Information Card */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h1 className="text-2xl font-bold text-slate-900 mb-4">Order Details</h1>
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Order Number:</span>
              <span className="text-sm font-semibold text-slate-900">
                {order.order_number || order.id.slice(0, 8)}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Amount:</span>
              <span className="text-sm font-semibold text-slate-900">
                {formatCurrency(order.total_amount)}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Status:</span>
              <span
                className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${getStatusColor(
                  order.status
                )}`}
              >
                {order.status?.replace('_', ' ').toUpperCase()}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Date:</span>
              <span className="text-sm font-semibold text-slate-900">
                {formatDate(order.created_at)}
              </span>
            </div>
            {order.drops?.[0] && (
              <>
                <div className="pt-4 border-t border-slate-200">
                  <p className="text-sm font-medium text-slate-900 mb-2">Pickup Location:</p>
                  <p className="text-sm text-slate-600">{order.drops[0].pickup_address}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-slate-900 mb-2">Delivery Location:</p>
                  <p className="text-sm text-slate-600">
                    {order.drops[order.drops.length - 1]?.delivery_address}
                  </p>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Timeline */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-900 mb-4">Order Timeline</h2>
          <div className="relative">
            {timelineEvents.map((event, index) => {
              const isLast = index === timelineEvents.length - 1;
              const isCompleted = event.date !== null;

              return (
                <div key={event.status} className="relative flex items-start space-x-4 pb-6">
                  {!isLast && (
                    <div
                      className={`absolute left-4 top-8 h-full w-0.5 ${
                        isCompleted ? 'bg-primary' : 'bg-slate-200'
                      }`}
                    />
                  )}
                  <div
                    className={`relative flex h-8 w-8 items-center justify-center rounded-full ${
                      isCompleted
                        ? 'bg-primary text-white'
                        : 'bg-slate-200 text-slate-400'
                    }`}
                  >
                    {isCompleted ? (
                      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                    ) : (
                      <div className="h-2 w-2 rounded-full bg-current" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p
                      className={`text-sm font-medium ${
                        isCompleted ? 'text-slate-900' : 'text-slate-500'
                      }`}
                    >
                      {event.label}
                    </p>
                    {event.date && (
                      <p className="text-xs text-slate-500 mt-1">{formatDate(event.date)}</p>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Right Panel - Map */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-slate-900">Map View</h2>
          <div className="flex gap-2">
            <button className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-50">
              Map
            </button>
            <button className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-50">
              Satellite
            </button>
          </div>
        </div>
        <div className="h-[600px] rounded-xl bg-slate-100 flex items-center justify-center">
          <div className="text-center">
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
                d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"
              />
            </svg>
            <p className="mt-2 text-sm text-slate-500">Map integration coming soon</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OrderTracking;
