import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

class UserProfile {
  final String id;
  final String email;
  final String? name;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}

class AuthService {
  final SupabaseClient _supabase;
  
  AuthService(this._supabase);

  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
  
  User? get currentUser => _supabase.auth.currentUser;

  /// Signs in the user with email and password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Signs up the user with email, password, and an optional name
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  /// Logs out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Sends a password reset email
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Gets user profile data from auth metadata
  UserProfile? getCurrentUserProfile() {
    final user = currentUser;
    if (user == null) return null;
    
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
    );
  }

  /// Updates the user's profile metadata
  Future<void> updateProfile({required String name}) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        data: {'name': name},
      ),
    );
  }
}
