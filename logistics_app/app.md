# Logistics Driver App - Application Documentation

## Overview

The Logistics Driver App is a Flutter-based mobile application designed for delivery drivers in the logistics platform. It enables drivers to manage their deliveries, track earnings, and stay connected with the logistics network in real-time.

**Version:** 1.0.0  
**Platform:** Flutter (iOS, Android, Web, Desktop)  
**Framework:** Flutter SDK ^3.10.0

---

## Application Description

### Purpose

The app serves as a comprehensive driver portal that empowers delivery drivers to:
- Accept and manage delivery orders
- Track order status and delivery progress
- Monitor earnings and wallet balance
- Request withdrawals
- Manage their online/offline availability
- View transaction history
- Access profile and vehicle information

### Core Features

#### 1. **Authentication & User Management**
- Phone number and PIN-based authentication
- Secure token-based session management
- Automatic token verification on app launch
- Session persistence across app restarts
- Secure logout functionality

#### 2. **Order Management**
- **Order List View**: View all orders with filtering options
  - All orders
  - Active orders (pending, in_transit)
  - Completed orders (delivered)
- **Order Details**: Comprehensive order information including:
  - Order ID and creation date
  - Pickup location with full address
  - Multiple drop locations with recipient details
  - Order status tracking (pending, in_transit, delivered, cancelled)
  - Total order amount
  - Step-by-step delivery progress

#### 3. **Dashboard & Home**
- Personalized greeting based on time of day
- Today's summary statistics:
  - Number of deliveries completed
  - Total earnings for the day
- Recent orders preview
- Online/Offline status toggle
- Quick access to wallet balance

#### 4. **Earnings & Wallet Management**
- **Wallet Overview**:
  - Available balance (withdrawable funds)
  - Pending balance (awaiting clearance)
  - Total earned (lifetime earnings)
- **Transaction History**: Complete list of all financial transactions
  - Credit transactions (earnings from deliveries)
  - Debit transactions (withdrawals)
  - Transaction dates and descriptions
- **Withdrawal Requests**: 
  - Request funds withdrawal to M-Pesa
  - Enter withdrawal amount and M-Pesa phone number
  - Real-time balance validation

#### 5. **Profile Management**
- Driver profile information:
  - Full name
  - Phone number
  - Vehicle type
  - Vehicle registration number
  - License number
- Wallet balance summary
- Help & Support access
- Contact support (phone and email)
- About information

#### 6. **Online Status Management**
- Toggle online/offline availability
- Real-time status synchronization with backend
- Visual indicators for current status

### Technical Architecture

#### **State Management**
- **Riverpod**: Primary state management solution
- Provider-based architecture for reactive UI updates
- Centralized authentication state management

#### **Backend Integration**
- RESTful API communication via HTTP
- Base URL configuration for different environments:
  - Development: Local server (localhost or 10.0.2.2 for Android emulator)
  - Production: Configurable via build-time constants
- Generic API service with support for:
  - GET, POST, PUT, DELETE operations
  - Automatic authentication header injection
  - Error handling and timeout management

#### **Data Storage**
- **SharedPreferences**: Local storage for:
  - Authentication tokens
  - User preferences
  - Session data

#### **UI/UX Design**
- Material Design 3 principles
- Responsive design supporting:
  - Portrait and landscape orientations
  - Different screen sizes
  - Safe area handling (notches, status bars)
- Custom theme system with:
  - Primary and accent colors
  - Gradient backgrounds
  - Consistent spacing and typography
  - Adaptive sizing based on screen dimensions

#### **Dependencies & Integrations**

**Core Dependencies:**
- `flutter_riverpod`: State management
- `http`: HTTP client for API calls
- `dio`: Advanced HTTP client (alternative)
- `shared_preferences`: Local data persistence
- `intl`: Internationalization and date formatting

**Maps & Location:**
- `google_maps_flutter`: Google Maps integration
- `geolocator`: Location services

**Media & Capture:**
- `image_picker`: Camera and gallery access
- `signature`: Digital signature capture

**UI Components:**
- `flutter_svg`: SVG image support
- `cached_network_image`: Image caching
- `font_awesome_flutter`: Icon library
- `flutter_local_notifications`: Local notifications

**Utilities:**
- `url_launcher`: External URL/phone/email launching
- `path_provider`: File system paths

### Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          # App configuration, API URLs, constants
│   ├── services/
│   │   └── api_service.dart          # API communication service
│   ├── theme/
│   │   └── app_theme.dart            # Theme definitions
│   └── utils/
│       └── responsive.dart           # Responsive design utilities
├── presentation/
│   ├── pages/
│   │   ├── earnings/
│   │   │   └── earnings_page.dart    # Earnings and wallet page
│   │   ├── home/
│   │   │   └── home_page.dart        # Dashboard/home page
│   │   ├── login/
│   │   │   └── login_page.dart       # Authentication page
│   │   ├── orders/
│   │   │   └── orders_page.dart      # Orders list and details
│   │   └── profile/
│   │       └── profile_page.dart     # Profile management
│   ├── providers/
│   │   └── auth_provider.dart        # Authentication state provider
│   ├── routes/
│   │   └── app_router.dart           # Navigation routing
│   └── widgets/
│       └── bottom_nav_bar.dart       # Bottom navigation bar
└── main.dart                          # App entry point
```

### Date & Time Formatting

The app uses standardized date and time formats:
- **Date Format**: DD/MM/YYYY
- **Time Format**: HH:MM:SS
- **DateTime Format**: DD/MM/YYYY HH:MM:SS

### Currency

- **Currency Symbol**: Ksh (Kenyan Shilling)
- All monetary values displayed with Ksh prefix

---

## Security

### Authentication Security

#### **1. Login Authentication**
- **Phone Number Validation**:
  - Country code selection (default: +254 for Kenya)
  - Minimum 9-digit phone number validation
  - Input sanitization (digits only)
  
- **PIN Security**:
  - Minimum 4-digit PIN requirement
  - PIN input masking (obscure text)
  - Toggle visibility option for user convenience
  - Digits-only input validation

- **Authentication Flow**:
  ```
  1. User enters phone number and PIN
  2. App sends credentials to backend API: POST /api/auth/drivers/login
  3. Backend validates credentials
  4. Backend returns JWT token and user data
  5. App stores token securely in SharedPreferences
  6. App updates authentication state
  7. App navigates to home screen
  ```

#### **2. Token Management**

**Token Storage:**
- Authentication tokens stored in `SharedPreferences` with key `'auth_token'`
- Tokens are stored locally on device
- **Token Sanitization in Logs**: All response bodies are sanitized before logging to prevent token exposure
  - Tokens are automatically redacted from debug output
  - Response sanitization function removes `token` fields from logged data
  - Pattern matching ensures tokens are masked even if response structure varies

**Token Usage:**
- All authenticated API requests include token in `Authorization` header:
  ```
  Authorization: Bearer <token>
  ```
- Token automatically injected into request headers via `ApiService`
- Token verification on app launch to validate session

**Token Lifecycle:**
- Token obtained during login
- Token verified on app initialization
- Token removed on logout or verification failure
- Token automatically included in all authenticated requests

#### **3. Session Management**

**Session Persistence:**
- App maintains session across restarts
- Automatic token verification on app launch
- Session invalidation on token verification failure
- Automatic logout on invalid/expired tokens

**Session Security:**
- Token verification endpoint: `GET /api/auth/verify`
- Failed verification triggers automatic token removal
- User redirected to login screen on session invalidation

### API Security

#### **1. Request Security**

**HTTPS Communication:**
- Production builds use HTTPS for all API communication
- Secure data transmission over encrypted channels
- Certificate pinning support (can be implemented)

**Request Headers:**
- All requests include standard headers:
  ```
  Content-Type: application/json
  Accept: application/json
  Authorization: Bearer <token> (for authenticated requests)
  ```

**Request Validation:**
- Input validation before API calls
- Phone number format validation
- Amount validation for withdrawals
- Error handling for network failures

#### **2. Error Handling**

**Network Error Handling:**
- Connection timeout: 30 seconds
- Socket exception handling
- Connection refused detection
- User-friendly error messages
- Automatic retry logic (can be implemented)

**API Error Handling:**
- HTTP status code validation (200-299 for success)
- Error message extraction from API responses
- Graceful degradation on API failures
- User notification via SnackBar messages

#### **3. Data Transmission**

**Sensitive Data Protection:**
- Passwords/PINs never logged or stored in plain text
- Phone numbers transmitted securely
- Financial data (amounts) validated before transmission
- No sensitive data in URL parameters

**Request Body Security:**
- JSON encoding for all request bodies
- Input sanitization before encoding
- No sensitive data in query parameters

### Data Security

#### **1. Local Data Storage**

**SharedPreferences Security:**
- Authentication tokens stored in SharedPreferences
- No sensitive user data stored locally (except tokens)
- Token storage isolated from other app data

**Data Persistence:**
- Minimal local data storage
- No caching of sensitive user information
- Profile data fetched fresh from API

#### **2. Data Validation**

**Input Validation:**
- Phone number format validation
- PIN length and format validation
- Amount validation (positive numbers)
- Required field validation

**Output Sanitization:**
- Error messages sanitized before display
- User input sanitized before API transmission
- No raw API error messages exposed to users

### Authentication State Security

#### **1. State Management Security**

**Riverpod Provider Security:**
- Authentication state managed centrally
- State changes trigger UI updates automatically
- No authentication state stored in widget state
- Secure state transitions

**Authentication Flow:**
```dart
1. AuthProvider initializes and verifies existing token
2. If token valid: User authenticated, navigate to home
3. If token invalid: User logged out, navigate to login
4. Login action updates AuthProvider state
5. Logout action clears AuthProvider state
```

#### **2. Route Protection**

**Navigation Security:**
- Main app checks authentication state before rendering
- Authenticated users see HomePage
- Unauthenticated users see LoginPage
- Automatic navigation on state changes

### Security Best Practices Implemented

#### **1. Secure Coding Practices**
- ✅ No hardcoded credentials
- ✅ Environment-based configuration
- ✅ Input validation on all user inputs
- ✅ Error handling without exposing sensitive information
- ✅ Secure token storage
- ✅ Automatic token cleanup on logout

#### **2. Network Security**
- ✅ HTTPS for production (configurable)
- ✅ Request timeout handling
- ✅ Network error detection
- ✅ Secure header management
- ✅ Bearer token authentication

#### **3. Session Security**
- ✅ Token verification on app launch
- ✅ Automatic session invalidation on token expiry
- ✅ Secure logout with token removal
- ✅ Session persistence across app restarts

#### **4. Data Protection**
- ✅ Minimal local data storage
- ✅ No sensitive data in logs
- ✅ Input sanitization
- ✅ Secure data transmission

### Security Recommendations

#### **1. Enhanced Security Measures (Future Implementation)**

**Token Security:**
- Implement token refresh mechanism
- Add token expiration handling
- Implement secure token storage using Flutter Secure Storage
- Add biometric authentication option

**Network Security:**
- Implement certificate pinning
- Add request/response encryption for sensitive data
- Implement API rate limiting on client side
- Add request signing for critical operations

**Data Security:**
- Implement local data encryption
- Add secure backup/restore functionality
- Implement data retention policies
- Add audit logging for sensitive operations

**Authentication Security:**
- Add two-factor authentication (2FA)
- Implement device fingerprinting
- Add suspicious activity detection
- Implement account lockout after failed attempts

#### **2. Compliance Considerations**

**Data Privacy:**
- Ensure GDPR compliance for user data
- Implement data deletion on user request
- Add privacy policy acceptance
- Implement data export functionality

**Financial Security:**
- PCI DSS compliance for payment data (if applicable)
- Secure withdrawal request handling
- Transaction audit trails
- Fraud detection mechanisms

### Security Configuration

#### **Environment Variables**

The app uses compile-time constants for security-sensitive configuration:

```dart
--dart-define=API_BASE_URL=https://your-backend.onrender.com/api
--dart-define=GOOGLE_MAPS_API_KEY=your-maps-key
```

**Development:**
- Default localhost URLs for development
- Platform-specific URL handling:
  - Android Emulator: `http://10.0.2.2:3000/api`
  - iOS Simulator: `http://localhost:3000/api`
  - Physical Devices: Use computer's IP address

**Production:**
- HTTPS endpoints required
- Secure API keys management
- Environment-specific configuration

### Security Monitoring

#### **Current Monitoring**
- Error logging via `debugPrint` (development)
- User-facing error messages
- Network error detection and reporting

#### **Recommended Monitoring**
- Crash reporting (e.g., Sentry, Firebase Crashlytics)
- Security event logging
- Authentication failure tracking
- API error rate monitoring
- User activity analytics

---

## Development & Deployment

### Setup Requirements

1. **Flutter SDK**: Version ^3.10.0 or higher
2. **Dependencies**: Run `flutter pub get`
3. **Configuration**: Set environment variables for API URLs and keys
4. **Backend**: Ensure backend server is running and accessible

### Build Configuration

**Development:**
```bash
flutter run
```

**Production:**
```bash
flutter build apk --dart-define=API_BASE_URL=https://your-api.com/api
flutter build ios --dart-define=API_BASE_URL=https://your-api.com/api
```

### Testing

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows
- Security testing for authentication flows

---

## Support & Contact

**Support Email:** support@xobo.co.ke  
**Support Phone:** +254 700 000 000  
**Version:** 1.0.0  
**Copyright:** © 2025 Xobo Logistics

---

## Changelog

### Version 1.0.0
- Initial release
- Driver authentication
- Order management
- Earnings and wallet features
- Profile management
- Online/offline status toggle

---

*This documentation is maintained as part of the Logistics Driver App project. For updates or questions, please contact the development team.*

