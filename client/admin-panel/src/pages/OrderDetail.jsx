import { useParams } from 'react-router-dom';

const OrderDetail = () => {
  const { orderId } = useParams();

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div className="bg-white p-6 rounded-lg shadow">
        <h1 className="text-2xl font-bold mb-4">Order Timeline</h1>
        <p>Order ID: {orderId}</p>
        {/* Timeline component will go here */}
      </div>
      <div className="bg-white p-6 rounded-lg shadow">
        <h2 className="text-xl font-semibold mb-4">Order Details</h2>
        <div className="space-y-4">
          {/* Tabbed interface will go here */}
        </div>
      </div>
    </div>
  );
};

export default OrderDetail;

