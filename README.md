# Logistics Platform

Complete logistics platform similar to Sendy (Kenya) with Customer Panel, Admin Panel, and Driver App.

## Tech Stack

- **Backend**: Express.js, Node.js, Supabase
- **Frontend**: React.js (Customer Panel, Admin Panel)
- **Mobile**: Flutter (Driver App)
- **Database**: Supabase PostgreSQL
- **Storage**: Supabase Storage
- **Additional**: Redis, Mailgun, Google Maps API, M-Pesa STK Push

## Project Structure

```
logistics_system/
├── backend/              # Express.js API server
│   ├── src/
│   │   ├── controllers/ # Request handlers
│   │   ├── services/    # Business logic
│   │   ├── repositories/ # Data access
│   │   ├── routes/      # API routes
│   │   ├── middleware/   # Express middleware
│   │   └── utils/       # Utilities
│   └── database/        # SQL schema and migrations
├── frontend/
│   ├── customer-panel/  # React.js customer interface
│   └── admin-panel/    # React.js admin interface
├── logistics_app/       # Flutter driver app
└── reference_images/    # UI/UX layout references
```

## Quick Start

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. **Configure environment variables** (REQUIRED):
   - Create a `.env` file in the `backend/` directory
   - Add your Supabase credentials (see [Environment Setup Guide](ENVIRONMENT_SETUP.md))
   - Required variables: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

4. Run database migrations in Supabase SQL editor:
   - Execute `database/schema.sql`
   - Execute `database/rls_policies.sql`

5. Start the server:
```bash
npm run dev
```

### Customer Panel Setup

1. Navigate to customer panel:
```bash
cd frontend/customer-panel
```

2. Install dependencies:
```bash
npm install
```

3. **Configure environment variables** (REQUIRED):
   - Create a `.env` file in the `frontend/customer-panel/` directory
   - Add your Supabase credentials (see [Environment Setup Guide](ENVIRONMENT_SETUP.md))
   - Required variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`

4. Start development server:
```bash
npm run dev
```

### Admin Panel Setup

1. Navigate to admin panel:
```bash
cd frontend/admin-panel
```

2. Install dependencies:
```bash
npm install
```

3. **Configure environment variables** (REQUIRED):
   - Create a `.env` file in the `frontend/admin-panel/` directory
   - Add your Supabase credentials (see [Environment Setup Guide](ENVIRONMENT_SETUP.md))
   - Required variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`

4. Start development server:
```bash
npm run dev
```

### Driver App Setup

1. Navigate to Flutter app:
```bash
cd logistics_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. **Configure environment variables** (REQUIRED):
   - Environment variables must be passed via `--dart-define` flags
   - See [Environment Setup Guide](ENVIRONMENT_SETUP.md) for details
   - Required variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`

4. Run the app:
```bash
flutter run \
  --dart-define=SUPABASE_URL=your-url \
  --dart-define=SUPABASE_ANON_KEY=your-key
```

## Features

### Customer Panel
- Order creation with distance-based or per-box pricing
- Order tracking with timeline and map
- Order history with expandable rows
- Multi-drop support (retail: 4 max, corporate: unlimited)
- Payment integration (M-Pesa, wallet, invoice)

### Admin Panel
- Order management dashboard
- Driver management
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

See `backend/API_DOCUMENTATION.md` for complete API documentation.

## Pricing Engine

See `backend/PRICING_ENGINE.md` for pricing calculation details.

## Database Schema

See `backend/database/schema.sql` for complete database schema.

## Environment Variables

**⚠️ IMPORTANT:** All hardcoded credentials have been removed. You **must** configure environment variables before running any component.

See **[ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md)** for complete setup instructions, including:
- How to get Supabase credentials
- Step-by-step setup for each component
- Troubleshooting guide
- Security best practices

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

