import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final authProvider = ChangeNotifierProvider<AuthProviderNotifier>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthProviderNotifier(authService);
});

class AuthProviderNotifier extends ChangeNotifier {
  final AuthService _authService;
  UserProfile? _user;
  bool _isLoading = false;

  AuthProviderNotifier(this._authService) {
    _init();
  }

  void _init() {
    _user = _authService.getCurrentUserProfile();
    // Listen to Supabase auth state changes
    _authService.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _user = _authService.getCurrentUserProfile();
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Handles user login request
  Future<String?> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final response = await _authService.signInWithEmailPassword(
        email: email, 
        password: password,
      );
      if (response.user == null) {
        return "Login failed. Please check your credentials.";
      }
      return null; // Success
    } on AuthException catch (e) {
      debugPrint("Authentication error: ${e.message}");
      return e.message;
    } catch (e) {
      debugPrint("Unknown error: $e");
      return "An unexpected error occurred.";
    } finally {
      _setLoading(false);
    }
  }

  /// Handles user signup request
  Future<String?> register({required String name, required String email, required String password}) async {
    _setLoading(true);
    try {
      final response = await _authService.signUp(
        email: email, 
        password: password,
        name: name,
      );
      if (response.user == null) {
        return "Registration failed.";
      }
      return null; // Success
    } on AuthException catch (e) {
      debugPrint("Registration error: ${e.message}");
      return e.message;
    } catch (e) {
      debugPrint("Unknown error: $e");
      return "An unexpected error occurred.";
    } finally {
      _setLoading(false);
    }
  }

  /// Handles forgot password request
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      debugPrint("Reset password error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handles logout request
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint("Logout error: $e");
    } finally {
      _setLoading(false);
    }
  }

  /// Handles updating the user's name
  Future<bool> updateProfile(String newName) async {
    _setLoading(true);
    try {
      await _authService.updateProfile(name: newName);
      // Wait a bit for the session update to propagate or manually update _user
      _user = _authService.getCurrentUserProfile();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Update profile error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
