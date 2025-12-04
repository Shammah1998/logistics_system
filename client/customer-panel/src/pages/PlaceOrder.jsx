import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';

const PlaceOrder = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    pickupAddress: '',
    deliveryAddress: '',
    vehicleType: 'small',
    notes: '',
  });
  const [mapType, setMapType] = useState('map');
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // TODO: Implement order creation API call
      toast.success('Order placed successfully!');
      navigate('/orders');
    } catch (error) {
      toast.error('Failed to place order. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const vehicleTypes = [
    { id: 'small', name: 'Small', icon: '🚗', price: 'Ksh 500', description: 'Perfect for small packages' },
    { id: 'medium', name: 'Medium', icon: '🚐', price: 'Ksh 800', description: 'Perfect for medium packages' },
    { id: 'large', name: 'Large', icon: '🚚', price: 'Ksh 1200', description: 'Perfect for large packages' },
  ];

  return (
    <div className="relative h-[calc(100vh-8rem)] overflow-hidden">
      {/* Full-screen Map Background */}
      <div className="absolute inset-0 bg-slate-200">
        <div className="h-full w-full flex items-center justify-center">
          <div className="text-center">
            <svg
              className="mx-auto h-16 w-16 text-slate-400"
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
        {/* Fullscreen Toggle */}
        <button className="absolute top-4 right-4 rounded-lg border border-slate-300 bg-white p-2 text-slate-700 shadow-sm hover:bg-slate-50">
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"
            />
          </svg>
        </button>
      </div>

      {/* Form Overlay Panel */}
      <div className="absolute left-0 top-0 h-full w-full max-w-md overflow-y-auto bg-white shadow-2xl">
        <div className="p-6 space-y-4">
          {/* Map Type Toggle */}
          <div className="flex gap-2 rounded-lg border border-slate-200 bg-slate-50 p-1">
            <button
              type="button"
              onClick={() => setMapType('map')}
              className={`flex-1 rounded-md px-3 py-1.5 text-xs font-medium transition ${
                mapType === 'map'
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Map
            </button>
            <button
              type="button"
              onClick={() => setMapType('satellite')}
              className={`flex-1 rounded-md px-3 py-1.5 text-xs font-medium transition ${
                mapType === 'satellite'
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Satellite
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Pickup Address */}
            <div>
              <input
                type="text"
                name="pickupAddress"
                value={formData.pickupAddress}
                onChange={handleChange}
                required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
                placeholder="Enter pickup location"
              />
            </div>

            {/* Delivery Address */}
            <div>
              <input
                type="text"
                name="deliveryAddress"
                value={formData.deliveryAddress}
                onChange={handleChange}
                required
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
                placeholder="Enter delivery location"
              />
              <button
                type="button"
                className="mt-2 flex items-center gap-1.5 text-sm font-medium text-primary hover:text-primary-dark"
              >
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
                Add Destination
              </button>
            </div>

            {/* Vehicle Size Selection */}
            <div>
              <div className="flex gap-2">
                {vehicleTypes.map((vehicle) => (
                  <button
                    key={vehicle.id}
                    type="button"
                    onClick={() => setFormData((prev) => ({ ...prev, vehicleType: vehicle.id }))}
                    className={`flex-1 rounded-lg border-2 px-3 py-2 text-xs font-semibold transition ${
                      formData.vehicleType === vehicle.id
                        ? 'border-primary bg-primary/5 text-primary'
                        : 'border-slate-200 bg-white text-slate-700 hover:border-slate-300'
                    }`}
                  >
                    {vehicle.name}
                  </button>
                ))}
              </div>
            </div>

            {/* Vehicle Type List - Compact */}
            <div className="space-y-2">
              {vehicleTypes.map((vehicle) => (
                <div
                  key={vehicle.id}
                  onClick={() => setFormData((prev) => ({ ...prev, vehicleType: vehicle.id }))}
                  className={`flex items-center justify-between rounded-lg border-2 p-2.5 cursor-pointer transition ${
                    formData.vehicleType === vehicle.id
                      ? 'border-primary bg-primary/5'
                      : 'border-slate-200 hover:border-slate-300'
                  }`}
                >
                  <div className="flex items-center gap-2.5">
                    <span className="text-xl">{vehicle.icon}</span>
                    <div>
                      <p className="text-sm font-semibold text-slate-900">{vehicle.name}</p>
                    </div>
                  </div>
                  <span className="text-sm font-semibold text-slate-900">{vehicle.price}</span>
                </div>
              ))}
            </div>

            {/* Notes/Manifest/Schedule Tabs */}
            <div>
              <div className="flex gap-1 border-b border-slate-200">
                <button
                  type="button"
                  className="border-b-2 border-primary px-3 py-2 text-xs font-semibold text-slate-900"
                >
                  Notes
                </button>
                <button
                  type="button"
                  className="px-3 py-2 text-xs font-medium text-slate-600 hover:text-slate-900"
                >
                  Manifest
                </button>
                <button
                  type="button"
                  className="px-3 py-2 text-xs font-medium text-slate-600 hover:text-slate-900"
                >
                  Schedule
                </button>
              </div>
              <textarea
                name="notes"
                value={formData.notes}
                onChange={handleChange}
                rows={3}
                className="mt-2 w-full rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
                placeholder="Type your notes here"
              />
            </div>

            {/* Place Order Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-lg bg-slate-600 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-600 disabled:cursor-not-allowed disabled:bg-slate-300"
            >
              {loading ? 'Placing Order...' : 'Place Order'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default PlaceOrder;
