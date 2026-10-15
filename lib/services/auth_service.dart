import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthService {
  static const _usersKey = 'gymgear_users';
  static const _currentUserKey = 'gymgear_current_user';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<AppUser> getCurrentUser() async {
    final prefs = await _prefs;
    final existing = AppUser.decode(prefs.getString(_currentUserKey));
    if (existing != null) return existing;

    // Guests use the app without an email account.
    final guest = AppUser(
      uid: 'guest',
      displayName: 'Guest',
      email: null,
    );
    await prefs.setString(_currentUserKey, guest.encode());
    return guest;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await _prefs;
    final usersRaw = prefs.getString(_usersKey);
    final users = usersRaw == null
        ? <String, dynamic>{}
        : (jsonDecode(usersRaw) as Map<String, dynamic>);

    final record = users[normalizedEmail] as Map<String, dynamic>?;
    if (record == null || record['password'] != password) {
      throw Exception('Invalid email or password.');
    }

    final user = AppUser(
      uid: (record['uid'] ?? '').toString(),
      displayName: record['name']?.toString(),
      email: normalizedEmail,
    );
    await prefs.setString(_currentUserKey, user.encode());
    return user;
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await _prefs;
    final usersRaw = prefs.getString(_usersKey);
    final users = usersRaw == null
        ? <String, dynamic>{}
        : (jsonDecode(usersRaw) as Map<String, dynamic>);

    if (users.containsKey(normalizedEmail)) {
      throw Exception('An account with this email already exists.');
    }

    final user = AppUser(
      uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
      displayName: name.trim().isEmpty ? null : name.trim(),
      email: normalizedEmail,
    );

    users[normalizedEmail] = {
      'uid': user.uid,
      'name': user.displayName,
      'password': password,
    };

    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_currentUserKey, user.encode());
    return user;
  }

  Future<void> signOut() async {
    final prefs = await _prefs;
    await prefs.remove(_currentUserKey);
  }
}