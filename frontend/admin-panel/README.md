# Admin Panel

React.js admin panel for the logistics platform.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
```

3. Start development server:
```bash
npm run dev
```

## Features

- Order management with timeline view
- Driver management
- Customer management
- POD review and approval
- Withdrawal request approval
- Price card management
- Analytics dashboard

## Project Structure

```
src/
├── components/     # Reusable components (Sidebar, Header)
├── contexts/       # React contexts (Auth)
├── pages/          # Page components
├── services/       # API services
└── App.jsx         # Main app component
```

