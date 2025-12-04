import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // API Configuration - Backend API URL
  // =====================================================
  // DEVELOPMENT:
  //   - Android emulator: use 10.0.2.2 (maps to host localhost)
  //   - iOS simulator: localhost works
  //   - Physical device: use your computer's IP (e.g., http://192.168.1.100:3000/api)
  //
  // PRODUCTION:
  //   Build with: flutter build apk --dart-define=API_BASE_URL=https://your-backend.onrender.com/api
  //   Or for iOS: flutter build ipa --dart-define=API_BASE_URL=https://your-backend.onrender.com/api
  // =====================================================
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Auto-detect platform and use appropriate default for development
    if (kIsWeb) {
      // Web: use localhost
      return 'http://localhost:3000/api';
    } else if (Platform.isAndroid) {
      // Android emulator: use 10.0.2.2 (special IP that maps to host machine's localhost)
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      // iOS simulator: localhost works
      return 'http://localhost:3000/api';
    } else {
      // Desktop/other: use localhost
      return 'http://localhost:3000/api';
    }
  }

  // Google Maps API Key (optional)
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  // Date/Time Format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm:ss';

  // Currency Format
  static const String currencySymbol = 'Ksh';
}

