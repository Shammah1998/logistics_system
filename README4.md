# Logistics Platform - Core Components: Flutter Driver Mobile App

## Core Components (DEEP DIVE) - Flutter Driver Mobile App

The Driver Mobile App is a Flutter application that enables delivery drivers to manage their deliveries, track earnings, and interact with the logistics platform from their mobile devices. Built with Flutter for cross-platform compatibility (iOS, Android, Web, Desktop), it provides a native mobile experience optimized for drivers on the go.

---

## Overview

**Technology Stack:**
- **Framework**: Flutter SDK ^3.10.0
- **State Management**: Riverpod (Flutter Riverpod)
- **HTTP Client**: http package
- **Local Storage**: SharedPreferences
- **Authentication**: JWT tokens stored locally
- **UI**: Material Design 3 with custom theme
- **Responsive Design**: Custom responsive utilities

**Platform Support:**
- Android (primary target)
- iOS
- Web (optional)
- Desktop (optional)

---

## Directory Structure

```
logistics_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/                        # Core functionality
│   │   ├── config/
│   │   │   └── app_config.dart     # API URLs, constants, date/time formats
│   │   ├── services/
│   │   │   └── api_service.dart     # HTTP client, API calls
│   │   ├── theme/
│   │   │   └── app_theme.dart       # Theme definitions, colors, styles
│   │   └── utils/
│   │       └── responsive.dart      # Responsive design utilities
│   └── presentation/                # UI layer
│       ├── pages/                   # Screen components
│       │   ├── login/
│       │   │   └── login_page.dart
│       │   ├── home/
│       │   │   └── home_page.dart
│       │   ├── orders/
│       │   │   └── orders_page.dart
│       │   ├── earnings/
│       │   │   └── earnings_page.dart
│       │   └── profile/
│       │       └── profile_page.dart
│       ├── providers/
│       │   └── auth_provider.dart    # Authentication state (Riverpod)
│       ├── routes/
│       │   └── app_router.dart      # Navigation routing
│       └── widgets/
│           └── bottom_nav_bar.dart   # Bottom navigation bar
├── android/                         # Android-specific configuration
├── ios/                             # iOS-specific configuration
├── pubspec.yaml                     # Dependencies and metadata
└── README.md                        # App-specific documentation
```

---

## Main Entry Point: `main.dart`

**File:** `lib/main.dart`

**Purpose:** Initializes the Flutter app, sets up Riverpod provider scope, and determines initial route based on authentication state.

**What It Does:**
1. **Widgets Binding**: Ensures Flutter widgets are initialized
2. **Provider Scope**: Wraps app with `ProviderScope` for Riverpod state management
3. **Auth State Check**: Watches `authProvider` to determine if user is authenticated
4. **Route Decision**: Shows `HomePage` if authenticated, `LoginPage` if not
5. **Theme Configuration**: Applies custom theme from `AppTheme`

**Key Code Structure:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: LogisticsApp(),
    ),
  );
}

class LogisticsApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: authState.isAuthenticated ? const HomePage() : const LoginPage(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
```

**Why This Design:**
- **Reactive Navigation**: Automatically navigates based on auth state changes
- **Provider Scope**: Makes Riverpod providers available throughout the app
- **Simple Routing**: Uses MaterialApp's built-in routing with custom route generator

---

## Core Configuration: `core/config/app_config.dart`

**Purpose:** Centralizes configuration values like API URLs, date formats, and constants.

**Key Features:**

**API Base URL Configuration:**
- **Development**: Auto-detects platform (Android emulator uses `10.0.2.2`, iOS uses `localhost`)
- **Production**: Uses `API_BASE_URL` from build-time constants (`--dart-define`)
- **Platform-Specific**: Handles Android emulator's special IP address requirement

**Date/Time Formats:**
- **Date**: `DD/MM/YYYY` (matches system requirement)
- **Time**: `HH:MM:SS` (matches system requirement)
- **DateTime**: `DD/MM/YYYY HH:MM:SS`

**Currency Format:**
- **Symbol**: `Ksh` (Kenyan Shilling)
- Used consistently throughout the app

**Why Centralized:**
- **Single Source of Truth**: All configuration in one place
- **Easy Updates**: Change once, affects entire app
- **Environment-Specific**: Different values for dev/prod

---

## API Service: `core/services/api_service.dart`

**Purpose:** Provides a centralized HTTP client for all API communication with the backend.

**Key Features:**

**Singleton Pattern:**
- Single instance shared across the app
- Ensures consistent configuration

**Token Management:**
- **Storage**: Tokens stored in SharedPreferences with key `'auth_token'`
- **Automatic Injection**: All authenticated requests include `Authorization: Bearer <token>` header
- **Token Retrieval**: `_getToken()` method retrieves token before each request
- **Token Removal**: `_removeToken()` clears token on logout

**Request Methods:**
- `get(endpoint)` - GET requests
- `post(endpoint, body)` - POST requests
- `put(endpoint, body)` - PUT requests
- `delete(endpoint)` - DELETE requests

**Driver-Specific Methods:**
- `login(phone, password)` - Driver authentication
- `verifyToken()` - Token validation
- `logout()` - Session termination
- `getProfile()` - Driver profile data
- `getOrders({status})` - Driver's orders
- `getWallet()` - Wallet balance and transactions
- `updateOnlineStatus(isOnline)` - Online/offline toggle
- `requestWithdrawal(amount, phoneNumber)` - Withdrawal request

**Error Handling:**
- **Network Errors**: Catches `SocketException`, provides helpful error messages
- **Timeout Handling**: 30-second timeout with clear error messages
- **Response Validation**: Checks HTTP status codes (200-299 for success)
- **User-Friendly Messages**: Converts technical errors to readable messages

**Token Sanitization:**
- **Logging Safety**: `_sanitizeResponseBody()` removes tokens from debug output
- **Multiple Patterns**: Handles various token formats in response bodies
- **Security**: Prevents token exposure in logs

**Why This Design:**
- **Centralized**: All API calls go through one service
- **Consistent**: Same error handling and token management everywhere
- **Maintainable**: Easy to update API base URL or add new endpoints
- **Secure**: Tokens never logged, automatically included in requests

---

## Authentication Provider: `presentation/providers/auth_provider.dart`

**Purpose:** Manages authentication state using Riverpod's StateNotifier pattern.

**State Structure:**

```dart
class AuthState {
  final Map<String, dynamic>? user;  // User data from API
  final bool isLoading;              // Loading indicator
  
  bool get isAuthenticated => user != null;
}
```

**Key Functions:**

**`_init()` (Constructor)**
- Called when provider is first accessed
- Verifies existing token on app startup
- Sets user state if token is valid
- Clears user state if token is invalid

**`signIn(phone, password)`**
- Calls `apiService.login(phone, password)`
- Stores returned token in SharedPreferences
- Updates state with user data
- Throws exception on failure

**`signOut()`**
- Calls `apiService.logout()` (optional, mainly for API consistency)
- Removes token from SharedPreferences
- Clears user state
- Triggers navigation to login (handled by main.dart)

**Why Riverpod:**
- **Reactive**: UI automatically updates when auth state changes
- **Provider Pattern**: Standard Flutter state management approach
- **Type-Safe**: Compile-time safety for state access
- **Testable**: Easy to mock and test

**Usage Example:**
```dart
final authState = ref.watch(authProvider);

if (authState.isLoading) return LoadingSpinner();
if (!authState.isAuthenticated) return LoginPage();

final user = authState.user;
// Use user data
```

---

## Page Components

### Login Page: `presentation/pages/login/login_page.dart`

**Purpose:** Handles driver authentication with phone number and PIN.

**Features:**
- **Phone Input**: Text field with country code support (+254 for Kenya)
- **PIN Input**: Secure text field (obscured) with toggle visibility
- **Validation**: 
  - Phone: Minimum 9 digits
  - PIN: Minimum 4 digits
- **Loading State**: Shows loading indicator during login
- **Error Handling**: Displays error messages for failed login attempts
- **Auto-Navigation**: Automatically navigates to HomePage on success

**Login Flow:**
1. User enters phone number and PIN
2. User taps "Login" button
3. App calls `authProvider.signIn(phone, password)`
4. API service makes POST request to `/api/auth/drivers/login`
5. Backend validates credentials and returns token
6. Token stored in SharedPreferences
7. Auth state updated
8. App navigates to HomePage

**Why Phone + PIN:**
- **Simple**: Easy for drivers to remember
- **Mobile-First**: Phone numbers are universal
- **Secure**: PIN is hashed and stored securely in Supabase Auth

### Home Page: `presentation/pages/home/home_page.dart`

**Purpose:** Main dashboard showing driver overview, stats, and recent orders.

**Features:**

**Header Section:**
- **Greeting**: Time-based greeting (Good morning/afternoon/evening)
- **Driver Name**: Displays driver's full name
- **Avatar**: Initial letter in circular avatar
- **Refresh Button**: Manual data refresh

**Online Status Card:**
- **Toggle Switch**: Online/Offline status toggle
- **Visual Indicator**: Green dot when online, gray when offline
- **API Integration**: Updates status via `/api/drivers/me/status`

**Today's Summary:**
- **Deliveries Count**: Number of completed deliveries today
- **Earnings**: Total earned amount (from wallet)
- **Card Layout**: Two stat cards side by side

**Recent Orders:**
- **Order Cards**: Shows last 3 orders
- **Status Badges**: Color-coded status indicators
- **Order Amount**: Displays order total
- **Empty State**: Message when no orders exist

**Navigation:**
- **Bottom Navigation**: Tab bar for Home, Orders, Earnings, Profile
- **IndexedStack**: Maintains state of all tabs (no rebuild on tab switch)

**Data Loading:**
- **On Mount**: Fetches wallet and orders on page load
- **Pull to Refresh**: RefreshIndicator for manual refresh
- **Loading State**: Shows CircularProgressIndicator while loading

**Why This Layout:**
- **Quick Overview**: Driver sees key info at a glance
- **Easy Access**: Most common actions (orders, earnings) in bottom nav
- **Status Management**: Online/offline toggle prominently displayed

### Orders Page: `presentation/pages/orders/orders_page.dart`

**Purpose:** Displays all driver orders with filtering and detailed views.

**Features:**

**Tab Navigation:**
- **All Tab**: Shows all orders
- **Active Tab**: Shows pending and in_transit orders
- **Completed Tab**: Shows delivered orders
- **Dynamic Counts**: Tab labels show order counts

**Order Cards:**
- **Order ID**: First 8 characters of order UUID
- **Status Badge**: Color-coded status (pending, assigned, in_transit, delivered, cancelled)
- **Route Visualization**: Pickup (green dot) → Drops (red dot) with connecting line
- **Pickup Address**: Truncated address display
- **Drop Count**: Number of delivery locations
- **Order Amount**: Total order value in KES
- **View Details**: Tap to see full order details

**Order Details Modal:**
- **Bottom Sheet**: Draggable modal with order details
- **Order Information**: Order number, date, status, amount
- **Pickup Location**: Full pickup address
- **Drop Locations**: List of all drop locations with recipient info
- **Drop Status**: Individual status for each drop

**Empty States:**
- **No Orders**: Message when no orders exist
- **No Active Orders**: Message when no active orders
- **No Completed Orders**: Message when no completed orders
- **Contextual Icons**: Different icons for different empty states

**Why Tabbed Interface:**
- **Organization**: Separates orders by status
- **Quick Filtering**: Easy to find active vs completed orders
- **Better UX**: Reduces scrolling through long lists

### Earnings Page: `presentation/pages/earnings/earnings_page.dart`

**Purpose:** Displays driver wallet balance, earnings, and transaction history.

**Features:**

**Header Section:**
- **Available Balance**: Large display of withdrawable balance
- **Pending Balance**: Balance awaiting clearance
- **Total Earned**: Lifetime earnings
- **Gradient Background**: Visual appeal with primary gradient

**Quick Actions:**
- **Withdraw Button**: Opens withdrawal request dialog
- **Statements Button**: Placeholder for future feature

**Withdrawal Dialog:**
- **Amount Input**: Text field for withdrawal amount
- **M-Pesa Number**: Phone number for M-Pesa transfer
- **Validation**: 
  - Amount must be positive and less than balance
  - Phone number required
- **Available Balance Display**: Shows current balance
- **Submit**: Creates withdrawal request via API

**Transaction History:**
- **Transaction Cards**: List of recent transactions
- **Credit Transactions**: Green indicator for earnings
- **Debit Transactions**: Red indicator for withdrawals
- **Transaction Details**: Description, date, amount
- **Empty State**: Message when no transactions exist

**Data Flow:**
1. Page loads → Fetches wallet from `/api/drivers/me/wallet`
2. Displays balance and transactions
3. User requests withdrawal → POST to `/api/drivers/me/withdraw`
4. Success → Refreshes wallet data
5. Transaction appears in history after admin approval

**Why This Design:**
- **Clear Financial Overview**: Driver sees all financial info in one place
- **Easy Withdrawals**: Simple process for requesting funds
- **Transaction Transparency**: Full history of earnings and withdrawals

### Profile Page: `presentation/pages/profile/profile_page.dart`

**Purpose:** Displays driver profile information and provides account management.

**Features:**
- **Profile Information**: Name, phone, email
- **Vehicle Details**: Vehicle type, registration number, license number
- **Wallet Summary**: Quick view of balance
- **Help & Support**: Contact information
- **Logout**: Sign out functionality

**Note:** Implementation details may vary, but typically includes:
- Profile data from `/api/drivers/me/profile`
- Editable fields (if allowed)
- Support contact information
- Logout button that calls `authProvider.signOut()`

---

## State Management with Riverpod

**Why Riverpod:**
- **Type-Safe**: Compile-time safety for providers
- **Reactive**: Automatic UI updates when state changes
- **Testable**: Easy to mock providers in tests
- **Performance**: Efficient rebuilds (only affected widgets rebuild)

**Provider Types Used:**

**StateNotifierProvider:**
- `authProvider` - Manages authentication state
- State changes trigger UI rebuilds automatically

**StateProvider:**
- `onlineStatusProvider` - Simple boolean state for online/offline status
- Lightweight for simple state

**Usage Pattern:**
```dart
// Watch provider (rebuilds on change)
final authState = ref.watch(authProvider);

// Read provider (no rebuild)
final apiService = ref.read(apiServiceProvider);

// Update state
ref.read(authProvider.notifier).signIn(phone, password);
```

---

## Responsive Design: `core/utils/responsive.dart`

**Purpose:** Provides responsive sizing utilities for different screen sizes.

**Features:**
- **Screen Size Detection**: Small, medium, large breakpoints
- **Orientation Detection**: Portrait vs landscape
- **Responsive Values**: Spacing, font sizes, icon sizes, container sizes
- **Consistent Scaling**: Maintains proportions across devices

**Why Custom Utility:**
- **Consistency**: Same responsive logic throughout app
- **Maintainability**: Change breakpoints in one place
- **Flexibility**: Easy to adjust for different device sizes

---

## Theme System: `core/theme/app_theme.dart`

**Purpose:** Defines app-wide visual styling and design tokens.

**Features:**
- **Color Palette**: Primary, accent, success, error, warning colors
- **Gradients**: Primary gradient for headers
- **Typography**: Font sizes, weights, styles
- **Material Theme**: Complete Material Design 3 theme configuration

**Why Centralized:**
- **Consistency**: Same colors and styles everywhere
- **Easy Theming**: Can switch themes or create dark mode
- **Design System**: Maintains design consistency

---

## Navigation System: `presentation/routes/app_router.dart`

**Purpose:** Defines app routes and navigation structure.

**Routes:**
- `/login` - Login page
- `/home` - Home page (with bottom nav)
- `/orders` - Orders page (accessible via bottom nav)
- `/earnings` - Earnings page (accessible via bottom nav)
- `/profile` - Profile page (accessible via bottom nav)

**Navigation Pattern:**
- **Bottom Navigation**: Primary navigation between main sections
- **Modal Bottom Sheets**: For detailed views (order details)
- **Route Generator**: Handles route generation and unknown routes

**Why This Pattern:**
- **Mobile-First**: Bottom nav is standard for mobile apps
- **Simple**: No complex navigation stack needed
- **User-Friendly**: Easy to switch between main sections

---

## How Flutter App Interacts with Backend

### Authentication Flow

```
1. Driver opens app
   ↓
2. main.dart checks authProvider state
   ↓
3. If no user:
   - Shows LoginPage
   ↓
4. Driver enters phone + PIN
   ↓
5. authProvider.signIn() called
   ↓
6. ApiService.login() makes POST /api/auth/drivers/login
   ↓
7. Backend validates credentials
   ↓
8. Backend returns JWT token + user data
   ↓
9. Token stored in SharedPreferences
   ↓
10. authProvider state updated
   ↓
11. main.dart detects auth change
   ↓
12. Navigates to HomePage
```

### Data Fetching Flow

```
1. Page component mounts (e.g., HomePage)
   ↓
2. initState() calls _loadData()
   ↓
3. ApiService methods called (e.g., getWallet(), getOrders())
   ↓
4. ApiService retrieves token from SharedPreferences
   ↓
5. HTTP request made with Authorization header
   ↓
6. Backend validates token and returns data
   ↓
7. Response parsed and returned to page
   ↓
8. setState() updates UI with data
```

### Order Status Update Flow

```
1. Driver views order in OrdersPage
   ↓
2. Driver performs action (e.g., picks up order)
   ↓
3. App calls ApiService.post('/orders/:id/status', { status: 'in_transit' })
   ↓
4. Backend updates order status
   ↓
5. Backend invalidates cache
   ↓
6. App receives success response
   ↓
7. App refreshes order list
   ↓
8. Updated status displayed in UI
```

---

## Key Design Patterns

### Singleton Pattern
- **ApiService**: Single instance ensures consistent configuration
- **SharedPreferences**: Single storage instance

### Provider Pattern (Riverpod)
- **State Management**: All state managed through providers
- **Dependency Injection**: Providers inject dependencies

### Repository Pattern (Partial)
- **ApiService**: Acts as repository for API calls
- **Future Enhancement**: Could add data repository layer

### Observer Pattern
- **Riverpod Watchers**: UI observes provider state changes
- **Automatic Updates**: UI rebuilds when state changes

---

## Error Handling Strategy

**Network Errors:**
- **SocketException**: Catches connection errors
- **Timeout**: 30-second timeout with clear messages
- **User-Friendly Messages**: Converts technical errors to readable text

**API Errors:**
- **Status Code Validation**: Checks 200-299 for success
- **Error Message Extraction**: Parses error messages from response
- **User Notification**: Shows SnackBar with error message

**Token Errors:**
- **Invalid Token**: Automatically removes token and redirects to login
- **Expired Token**: Same handling as invalid token

**Why This Approach:**
- **User Experience**: Users see helpful messages, not technical errors
- **Automatic Recovery**: Invalid tokens automatically trigger re-login
- **Consistent**: Same error handling pattern throughout app

---

## Security Considerations

**Token Storage:**
- **SharedPreferences**: Tokens stored in device storage
- **Not Encrypted**: Consider using flutter_secure_storage for production
- **Automatic Cleanup**: Tokens removed on logout

**Token Transmission:**
- **HTTPS Only**: Production uses HTTPS for all API calls
- **Header-Based**: Tokens sent in Authorization header, not URL
- **No Logging**: Tokens sanitized from all debug output

**Input Validation:**
- **Phone Numbers**: Validated before sending to API
- **PIN**: Minimum length validation
- **Amounts**: Positive number validation for withdrawals

**Why These Measures:**
- **Data Protection**: Tokens are sensitive and must be protected
- **Network Security**: HTTPS prevents man-in-the-middle attacks
- **Input Safety**: Validation prevents invalid data from reaching backend

---

## Platform-Specific Considerations

### Android
- **Emulator Networking**: Uses `10.0.2.2` to access host machine's localhost
- **Permissions**: May need location permissions for future map features
- **Build**: Generates APK for distribution

### iOS
- **Simulator Networking**: Uses `localhost` directly
- **Permissions**: Location and camera permissions for POD features
- **Build**: Generates IPA for App Store distribution

### Web (Optional)
- **CORS**: Must configure backend CORS for web origin
- **Storage**: Uses browser localStorage instead of SharedPreferences
- **Responsive**: Adapts to browser window size

---

**End of README4.md**

**Next Section:** README5.md will cover User Flows & Workflows for all user types.
