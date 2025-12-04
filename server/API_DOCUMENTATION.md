# API Documentation

## Base URL
```
http://localhost:3000/api
```

## Authentication
All endpoints (except `/health`) require authentication. Include the Supabase JWT token in the Authorization header:

```
Authorization: Bearer <supabase_jwt_token>
```

## Endpoints

### 1. POST /api/orders/create

Create a new order.

**Authentication:** Required (Customer or Admin)

**Request Body:**
```json
{
  "company_id": "uuid | null",
  "vehicle_type": "small | medium | large",
  "pricing_mode": "distance_based | per_box",
  "pickup_address": {
    "street": "123 Main St",
    "city": "Nairobi",
    "postal_code": "00100",
    "coordinates": {
      "lat": -1.2921,
      "lng": 36.8219
    }
  },
  "items": [
    {
      "description": "Box of electronics",
      "quantity": 2,
      "unit_price": 150.00
    }
  ],
  "drops": [
    {
      "recipient_name": "John Doe",
      "recipient_phone": "+254712345678",
      "address": {
        "street": "456 Oak Ave",
        "city": "Nairobi",
        "postal_code": "00200",
        "coordinates": {
          "lat": -1.3000,
          "lng": 36.8000
        }
      },
      "delivery_instructions": "Leave at front door"
    }
  ],
  "scheduled_pickup_time": "2024-01-15T10:00:00Z",
  "payment_method": "mpesa | wallet | invoice"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "order_id": "550e8400-e29b-41d4-a716-446655440000",
    "order_number": "ORD-2024-001234",
    "total_distance_km": 15.5,
    "base_price": 500.00,
    "total_price": 750.00,
    "payment_status": "pending",
    "status": "pending"
  }
}
```

**Error Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "vehicle_type",
      "message": "Vehicle type must be small, medium, or large"
    }
  ]
}
```

---

### 2. GET /api/orders/:orderId

Get order details by ID.

**Authentication:** Required (Customer, Driver, or Admin)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "order_number": "ORD-2024-001234",
    "customer_id": "uuid",
    "company_id": "uuid | null",
    "driver_id": "uuid | null",
    "vehicle_type": "medium",
    "pricing_mode": "distance_based",
    "pickup_address": {
      "street": "123 Main St",
      "city": "Nairobi",
      "coordinates": { "lat": -1.2921, "lng": 36.8219 }
    },
    "total_distance_km": 15.5,
    "base_price": 500.00,
    "total_price": 750.00,
    "status": "in_transit",
    "payment_status": "paid",
    "payment_method": "mpesa",
    "created_at": "2024-01-15T08:00:00Z",
    "items": [
      {
        "id": "uuid",
        "description": "Box of electronics",
        "quantity": 2,
        "unit_price": 150.00,
        "total_price": 300.00
      }
    ],
    "drops": [
      {
        "id": "uuid",
        "drop_sequence": 1,
        "recipient_name": "John Doe",
        "recipient_phone": "+254712345678",
        "address": { ... },
        "status": "delivered",
        "delivered_at": "2024-01-15T12:00:00Z"
      }
    ],
    "customer": {
      "id": "uuid",
      "email": "customer@example.com",
      "phone": "+254712345678"
    },
    "driver": {
      "id": "uuid",
      "license_number": "DL12345",
      "vehicle_type": "medium",
      "user": {
        "id": "uuid",
        "email": "driver@example.com",
        "phone": "+254798765432"
      }
    }
  }
}
```

---

### 3. POST /api/drivers/:driverId/assign-order

Assign an order to a driver.

**Authentication:** Required (Admin only)

**Request Body:**
```json
{
  "order_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "order_id": "550e8400-e29b-41d4-a716-446655440000",
    "driver_id": "660e8400-e29b-41d4-a716-446655440001",
    "assigned_at": "2024-01-15T09:00:00Z"
  }
}
```

---

### 4. POST /api/pods/upload

Upload proof of delivery (POD).

**Authentication:** Required (Driver only)

**Request:** multipart/form-data
- `order_id` (string, required): Order UUID
- `drop_id` (string, optional): Drop UUID (for multi-drop orders)
- `image` (file, required): POD image file
- `signature` (file, optional): Signature image
- `recipient_name` (string, required)
- `recipient_phone` (string, required)
- `notes` (string, optional): Additional notes

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "pod_id": "770e8400-e29b-41d4-a716-446655440002",
    "status": "pending",
    "image_url": "https://supabase.co/storage/v1/object/public/pods/image.jpg",
    "created_at": "2024-01-15T12:00:00Z"
  }
}
```

---

### 5. POST /api/pods/:podId/approve

Approve or reject a POD.

**Authentication:** Required (Admin only)

**Request Body:**
```json
{
  "approved": true,
  "rejection_reason": "string | null"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "pod_id": "770e8400-e29b-41d4-a716-446655440002",
    "status": "approved",
    "driver_payment": {
      "gross_amount": 750.00,
      "commission": 75.00,
      "insurance": 15.00,
      "withholding_tax": 37.50,
      "net_amount": 622.50
    },
    "wallet_updated": true
  }
}
```

**Rejection Response:**
```json
{
  "success": true,
  "data": {
    "pod_id": "770e8400-e29b-41d4-a716-446655440002",
    "status": "rejected",
    "rejection_reason": "Signature not clear"
  }
}
```

---

## Error Responses

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Authentication required"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Route not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Internal server error"
}
```

## Rate Limiting

API requests are rate-limited to 100 requests per 15 minutes per IP address.

## Date/Time Format

All timestamps are in ISO 8601 format (UTC):
```
2024-01-15T10:00:00Z
```

## Currency Format

All monetary values are in Kenyan Shillings (KES) and represented as numbers with 2 decimal places.

