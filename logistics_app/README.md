# Logistics Driver App

Flutter mobile application for drivers in the logistics platform.

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Configure environment variables in `lib/core/config/app_config.dart` or use compile-time constants:
```dart
--dart-define=SUPABASE_URL=your-url
--dart-define=SUPABASE_ANON_KEY=your-key
--dart-define=API_BASE_URL=your-api-url
--dart-define=GOOGLE_MAPS_API_KEY=your-maps-key
```

3. Run the app:
```bash
flutter run
```

## Features

- Driver authentication
- Order list (ongoing and completed)
- Order detail with step-by-step progress
- Map integration for navigation
- POD upload with camera and signature
- Wallet and earnings view
- Transaction history
- Withdrawal requests
- Profile management

## Project Structure

```
lib/
├── core/
│   ├── config/      # App configuration
│   └── theme/       # App theme
├── data/
│   ├── models/      # Data models
│   ├── repositories/ # Data repositories
│   └── services/    # API services
├── domain/
│   └── usecases/    # Business logic
└── presentation/
    ├── pages/       # Screen widgets
    ├── widgets/     # Reusable widgets
    ├── providers/   # State management (Riverpod)
    └── routes/      # Navigation
```

## Architecture

- **MVVM/Clean Architecture**: Separation of concerns
- **Riverpod**: State management
- **Supabase**: Authentication and backend
- **Google Maps**: Location and navigation
