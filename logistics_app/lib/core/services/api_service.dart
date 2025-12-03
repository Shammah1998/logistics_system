import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logistics_app/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => AppConfig.apiBaseUrl;
  
  // Get stored auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Store auth token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Remove auth token
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = json.decode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'Request failed with status ${response.statusCode}');
    }
  }

  // Driver login
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final url = '$baseUrl/auth/drivers/login';
      debugPrint('🔐 Attempting login to: $url');
      debugPrint('📱 Phone: $phone');
      
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'phone': phone,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the backend server is running at $baseUrl');
        },
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      final data = _handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        // Store token
        await _saveToken(data['data']['token']);
        debugPrint('✅ Login successful');
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network error: ${e.message}');
      throw Exception('Cannot connect to server. Please check:\n1. Backend server is running at $baseUrl\n2. For Android emulator, use: http://10.0.2.2:3000/api\n3. For physical device, use your computer IP: http://YOUR_IP:3000/api');
    } catch (e) {
      debugPrint('❌ Login error: $e');
      if (e.toString().contains('Connection refused') || e.toString().contains('SocketException')) {
        throw Exception('Cannot connect to server. Please check:\n1. Backend server is running at $baseUrl\n2. For Android emulator, use: http://10.0.2.2:3000/api\n3. For physical device, use your computer IP: http://YOUR_IP:3000/api');
      }
      throw Exception('Login error: ${e.toString()}');
    }
  }

  // Verify token
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Token verification failed');
      }
    } catch (e) {
      // If token is invalid, remove it
      await _removeToken();
      throw Exception('Token verification error: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _getHeaders(),
      );
    } catch (e) {
      // Continue with logout even if API call fails
      debugPrint('Logout API error: $e');
    } finally {
      // Always remove token locally
      await _removeToken();
    }
  }

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request error: ${e.toString()}');
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request error: ${e.toString()}');
    }
  }

  // Generic PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT request error: ${e.toString()}');
    }
  }

  // Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request error: ${e.toString()}');
    }
  }

  // ============================================
  // DRIVER-SPECIFIC ENDPOINTS
  // ============================================

  // Get driver profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await get('/drivers/me/profile');
      return response['data'] ?? {};
    } catch (e) {
      debugPrint('Get profile error: $e');
      return {};
    }
  }

  // Get driver orders
  Future<List<dynamic>> getOrders({String? status}) async {
    try {
      String endpoint = '/drivers/me/orders';
      if (status != null) {
        endpoint += '?status=$status';
      }
      final response = await get(endpoint);
      return response['data'] ?? [];
    } catch (e) {
      debugPrint('Get orders error: $e');
      return [];
    }
  }

  // Get wallet info
  Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await get('/drivers/me/wallet');
      return response['data'] ?? {};
    } catch (e) {
      debugPrint('Get wallet error: $e');
      return {'balance': 0, 'pendingBalance': 0, 'totalEarned': 0, 'transactions': []};
    }
  }

  // Update online status
  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      final response = await post('/drivers/me/status', {'isOnline': isOnline});
      return response['success'] == true;
    } catch (e) {
      debugPrint('Update status error: $e');
      return false;
    }
  }

  // Request withdrawal
  Future<Map<String, dynamic>> requestWithdrawal(double amount, String phoneNumber) async {
    try {
      final response = await post('/drivers/me/withdraw', {
        'amount': amount,
        'phoneNumber': phoneNumber,
      });
      return response;
    } catch (e) {
      debugPrint('Withdrawal error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}

