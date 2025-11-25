// lib/auth/user_service.dart
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfile {
  final String username;
  final String email;

  const UserProfile({required this.username, required this.email});

  UserProfile copyWith({String? username, String? email}) =>
      UserProfile(username: username ?? this.username, email: email ?? this.email);
}

class UserService {
  static const _storage = FlutterSecureStorage();

  // --- read token ---
  static Future<String?> get token async => await _storage.read(key: 'auth_token');

  static Future<void> clearToken() => _storage.delete(key: 'auth_token');

  // --- api calls ---
  static Future<UserProfile> fetchProfile() async {
    // note: replace with real API call using the token
    await Future.delayed(const Duration(milliseconds: 400));
    // mocked data:
    final username = await _storage.read(key: 'profile_username') ?? 'Player';
    final email = await _storage.read(key: 'profile_email') ?? 'player@example.com';
    return UserProfile(username: username, email: email);
  }

  // --- update profile (PUT /me) ---
  static Future<UserProfile> updateProfile({
    required String username,
    required String email,
    String? password, // if changing password
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // mocked: save to local storage
    await _storage.write(key: 'profile_username', value: username);
    await _storage.write(key: 'profile_email', value: email);

    return UserProfile(username: username, email: email);
  }

  // ---logout---
  static Future<void> logout() async {
    // if you have a logout API call, call it here
    await _storage.delete(key: 'auth_token');
    // clear saved profile data
    await _storage.delete(key: 'profile_username');
    await _storage.delete(key: 'profile_email');
  }
}
