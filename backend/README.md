# Logistics Platform Backend

Express.js backend API for the logistics platform using Supabase.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy `.env.example` to `.env` and fill in your configuration:
```bash
cp .env.example .env
```

3. Run database migrations:
- Execute `database/schema.sql` in your Supabase SQL editor
- Execute `database/rls_policies.sql` in your Supabase SQL editor

4. Start the server:
```bash
# Development
npm run dev

# Production
npm start
```

## Project Structure

```
backend/
├── src/
│   ├── controllers/     # Request handlers
│   ├── services/        # Business logic
│   ├── repositories/   # Data access layer
│   ├── routes/         # API routes
│   ├── middleware/     # Express middleware
│   └── utils/          # Utility functions
├── database/           # SQL schema and migrations
├── logs/               # Application logs
└── server.js          # Entry point
```

## API Endpoints

### Orders
- `POST /api/orders/create` - Create a new order
- `GET /api/orders/:orderId` - Get order by ID

### Drivers
- `POST /api/drivers/:driverId/assign-order` - Assign order to driver

### PODs
- `POST /api/pods/upload` - Upload proof of delivery
- `POST /api/pods/:podId/approve` - Approve/reject POD

## Environment Variables

See `.env.example` for all required environment variables.

