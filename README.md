# Logistics Platform

Complete logistics platform similar to Sendy (Kenya) with Customer Panel, Admin Panel, and Driver App.

Test system of an anticipated logistics system.

## Tech Stack

- **Server**: Express.js, Node.js, Supabase
- **Client**: React.js (Customer Panel, Admin Panel)
- **Mobile**: Flutter (Driver App)
- **Database**: Supabase PostgreSQL
- **Storage**: Supabase Storage
- **Additional**: Redis, Mailgun, Google Maps API, M-Pesa STK Push

## Project Structure

```
logistics_system/
├── .env                  # Root environment variables
├── .env.example          # Template for new setups
├── server/               # Express.js API server
│   ├── src/
│   │   ├── controllers/  # Request handlers
│   │   ├── services/     # Business logic
│   │   ├── repositories/ # Data access
│   │   ├── routes/       # API routes
│   │   ├── middleware/   # Express middleware
│   │   └── utils/        # Utilities
│   └── database/         # SQL schema and migrations
├── client/
│   ├── customer-panel/   # React.js customer interface
│   └── admin-panel/      # React.js admin interface
├── logistics_app/        # Flutter driver app
└── reference_images/     # UI/UX layout references
```

## Quick Start

### 1. Environment Setup

Copy the example environment file and fill in your Supabase credentials:

```bash
cp .env.example .env
```

Get your credentials from: https://app.supabase.com/project/_/settings/api

### 2. Server Setup

```bash
cd server
npm install
npm run dev
```

Server runs on: http://localhost:3000

### 3. Admin Panel Setup

```bash
cd client/admin-panel
npm install
npm run dev
```

Admin panel runs on: http://localhost:3002

### 4. Customer Panel Setup

```bash
cd client/customer-panel
npm install
npm run dev
```

Customer panel runs on: http://localhost:3001

### 5. Driver App Setup

```bash
cd logistics_app
flutter pub get
flutter run
```

## Features

### Customer Panel
- Order creation with distance-based or per-box pricing
- Order tracking with timeline and map
- Order history with expandable rows
- Multi-drop support (retail: 4 max, corporate: unlimited)
- Payment integration (M-Pesa, wallet, invoice)

### Admin Panel
- Dashboard with real-time statistics
- Order management with filtering
- Driver management (CRUD operations)
- Customer management
- POD review and approval
- Withdrawal request approval
- Price card management
- Analytics and reporting

### Driver App
- Order acceptance and management
- Step-by-step delivery workflow
- POD upload with camera and signature
- Map integration for navigation
- Wallet and earnings view
- Transaction history
- Withdrawal requests

## API Documentation

See `server/API_DOCUMENTATION.md` for complete API documentation.

### Available Endpoints

- `GET /api/dashboard/stats` - Dashboard statistics
- `GET /api/orders` - List orders
- `POST /api/orders/create` - Create order
- `GET /api/drivers` - List drivers
- `POST /api/drivers` - Create driver
- `GET /api/customers` - List customers
- `POST /api/auth/drivers/login` - Driver login
- `GET /api/auth/verify` - Verify token

## Pricing Engine

See `server/PRICING_ENGINE.md` for pricing calculation details.

## Database Schema

See `server/database/schema.sql` for complete database schema.

## Environment Variables

See **[ENV_SETUP_GUIDE.md](ENV_SETUP_GUIDE.md)** for complete setup instructions, including:
- How to get Supabase credentials
- Step-by-step setup for each component
- Production deployment guide
- Security best practices

## Production Deployment

### Server → Render
- Root directory: `server`
- Build command: `npm install`
- Start command: `npm start`

### Client Apps → Vercel
- Admin panel root directory: `client/admin-panel`
- Customer panel root directory: `client/customer-panel`

### Flutter App → APK
```bash
cd logistics_app
flutter build apk --release
```

## Development

### Code Standards
- Clean architecture with separation of concerns
- SOLID principles
- DRY and KISS principles
- ESLint and Prettier for code formatting

### Date/Time Format
- Date: DD/MM/YYYY
- Time: HH:MM:SS

## License

ISC
