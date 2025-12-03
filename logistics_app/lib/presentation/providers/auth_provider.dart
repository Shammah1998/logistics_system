import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistics_app/core/services/api_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final Map<String, dynamic>? user;
  final bool isLoading;

  AuthState({
    this.user,
    this.isLoading = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    Map<String, dynamic>? user,
    bool? isLoading,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final userData = await _apiService.verifyToken();
      if (userData['user'] != null) {
        state = state.copyWith(user: userData['user']);
      }
    } catch (e) {
      state = state.copyWith(clearUser: true);
    }
  }

  Future<void> signIn(String phone, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.login(phone, password);
      
      if (response['user'] != null) {
        state = state.copyWith(
          user: response['user'],
          isLoading: false,
        );
      } else {
        throw Exception('Login failed: Invalid response');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    debugPrint('🔓 Signing out...');
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Logout API error: $e');
    }
    // Clear user state - this will trigger navigation to login
    state = AuthState(user: null, isLoading: false);
    debugPrint('🔓 Signed out, user is now null');
  }
}
