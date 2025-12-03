# Customer Panel

React.js customer panel for the logistics platform.

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

- Order creation with distance-based or per-box pricing
- Order tracking with timeline and map
- Order history with expandable rows
- Real-time order status updates
- Google Maps integration for location selection

## Project Structure

```
src/
├── components/     # Reusable components
├── contexts/       # React contexts (Auth)
├── pages/          # Page components
├── services/       # API services
├── utils/          # Utility functions
└── App.jsx         # Main app component
```

